# Shared layout policy. Adapters supplied by displays.nix: niri_json,
# layout_jq, layout_flock, layout_service_is_running and request_layout_reconciliation.

read_layout_outputs() {
  outputs=$(niri_json outputs) || return 1
  # Connector names alone miss monitors exchanging connectors on resume.
  signature=$(layout_jq -ce '
    [to_entries[] | select(.value.logical != null) |
      {connector: .key, make: .value.make, model: .value.model,
       serial: .value.serial, logical: .value.logical}] | sort_by(.connector)
  ' <<<"$outputs") || return 1

  uw=$(layout_output_for_model AW3423DWF) || return 1
  aw=$(layout_output_for_model AW2725DF) || return 1
  edp=$(layout_output_for_model 0x4165) || return 1
  fallback_output=$edp
  if [ -z "$fallback_output" ]; then
    fallback_output=$(layout_jq -r '
      [to_entries[] | select(.value.logical != null) | .key] | sort | first // empty
    ' <<<"$outputs") || return 1
  fi

  expected_workspaces=$(layout_jq -cn --arg uw "$uw" --arg aw "$aw" \
    --arg edp "$edp" --arg fallback "$fallback_output" '
      if $uw != "" and $aw != "" then
        {web: $uw, terminal: $uw, chat: $aw, media: $aw}
        + (if $edp != "" then {notes: $edp} else {} end)
      elif $fallback != "" then
        {web: $fallback, terminal: $fallback, media: $fallback}
      else {} end
    ')
}

layout_output_for_model() {
  layout_jq -r --arg model "$1" '
    [to_entries[] | select(.value.logical != null and .value.model == $model) | .key]
    | sort | first // empty
  ' <<<"$outputs"
}

layout_workspaces_match() {
  layout_jq -e --argjson expected "$expected_workspaces" '
    . as $actual |
    all($expected | to_entries[];
      . as $target | any($actual[]; .name == $target.key and .output == $target.value))
    and all($actual[];
      if (.name == "notes" or .name == "chat" or .name == "layout-staging")
      then .name as $name | $expected | has($name)
      else true end)
  ' <<<"$workspaces" >/dev/null
}

wait_for_stable_layout_outputs() {
  local previous="" stable=0 sample
  # Four identical samples, 0.5s apart; give up after twelve samples.
  for ((sample = 0; sample < 12; sample++)); do
    if read_layout_outputs; then
      if [ "$signature" = "$previous" ]; then
        stable=$((stable + 1))
      else
        stable=0
      fi
      previous=$signature
      [ "$stable" -ge 3 ] && return 0
    else
      stable=0
      previous=""
    fi
    sleep 0.5
  done
  echo "Display topology did not settle; deferring layout" >&2
  return 1
}

reconcile_display_layout() {
  local attempt before
  for attempt in 1 2 3; do
    wait_for_stable_layout_outputs || continue
    if [ "$expected_workspaces" = '{}' ]; then
      echo "No active outputs; deferring display reconciliation"
      return 2
    fi
    before=$signature
    echo "Reconciling display layout (attempt $attempt): $expected_workspaces"
    if [ -n "$uw" ] && [ -n "$aw" ]; then
      arrange_docked
    else
      arrange_laptop
    fi

    # Re-read both topology and placement: a monitor may have reconnected while
    # we were moving windows. Never treat a partial pass as success.
    if read_layout_outputs && [ "$signature" = "$before" ]; then
      if workspaces=$(niri_json workspaces) && layout_workspaces_match; then
        echo "Display workspace placement verified: $expected_workspaces"
        return 0
      fi
    fi
    echo "Display topology or workspace placement changed during reconciliation" >&2
  done
  echo "Display layout failed verification after three attempts" >&2
  return 75
}

managed_layout_window_ids() {
  layout_jq -c '
    [.[] | select((.app_id // "" | ascii_downcase) as $app |
      ["spotify", "md.obsidian", "md.obsidian.obsidian", "google-chrome", "herdr-app", "slack"]
      | index($app)) | .id] | sort
  '
}

watch_display_layout() {
  local candidate="" previous="" known_ids="" windows ids new_window changed
  local attempts=0 failures=0 reason
  # Periodic validation also catches resume with no observable connector-set
  # change, and workspace drift after the final output event. It never touches
  # output modes or restarts DMS/the compositor.
  while sleep 2; do
    # The reconciler holds this lock through its entire layout pass. Its own
    # temporary staging workspaces must not trigger another restart.
    layout_flock -n 9 || continue
    if ! read_layout_outputs; then
      layout_flock -u 9
      candidate=""
      failures=$((failures + 1))
      if [ "$failures" -ge 3 ]; then
        echo "Display IPC failed three times; reconnecting watcher" >&2
        return 1
      fi
      continue
    fi
    if [ "$signature" != "$candidate" ]; then
      candidate=$signature
      layout_flock -u 9
      continue
    fi
    if [ "$expected_workspaces" = '{}' ]; then
      previous=$signature
      attempts=0
      failures=0
      layout_flock -u 9
      continue
    fi
    if ! workspaces=$(niri_json workspaces) || ! windows=$(niri_json windows) \
      || ! ids=$(managed_layout_window_ids <<<"$windows"); then
      layout_flock -u 9
      failures=$((failures + 1))
      if [ "$failures" -ge 3 ]; then
        echo "Display IPC failed three times; reconnecting watcher" >&2
        return 1
      fi
      continue
    fi
    failures=0

    changed=false
    [ -z "$previous" ] || [ "$signature" = "$previous" ] || changed=true
    new_window=false
    if [ -n "$known_ids" ] && layout_jq -e --argjson known "$known_ids" \
      'any(.[]; . as $id | $known | index($id) == null)' <<<"$ids" >/dev/null; then
      new_window=true
    fi
    known_ids=$ids
    previous=$signature
    if [ "$changed" = true ] || [ "$new_window" = true ]; then
      attempts=0
    fi

    reason=""
    if [ "$changed" = true ]; then
      reason="settled output topology changed"
    elif [ "$new_window" = true ]; then
      reason="managed application window opened"
    elif ! layout_workspaces_match; then
      reason="workspace-to-monitor placement mismatch"
    elif ! layout_service_is_running; then
      reason="display reconciliation service is not running"
    else
      attempts=0
    fi
    layout_flock -u 9
    [ -n "$reason" ] || continue

    # Three requests at most for a persistent mismatch. Successful placement,
    # a new settled topology or a new managed window re-arms the budget.
    [ "$attempts" -lt 3 ] || continue
    attempts=$((attempts + 1))
    echo "Requesting display reconciliation ($attempts/3): $reason; expected=$expected_workspaces"
    request_layout_reconciliation || echo "Could not request display reconciliation" >&2
    if [ "$attempts" -eq 3 ]; then
      echo "Display retry budget exhausted if placement remains incorrect" >&2
    fi
  done
}
