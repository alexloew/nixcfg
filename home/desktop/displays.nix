# Display wallpaper, startup apps, and topology-aware workspace reconciliation.
#
# Niri owns output modes and positions in home/desktop/niri.nix. This module
# never changes an external output mode, so it cannot recreate the old DRM
# modeset/uevent restart loop. It only reads the active topology, arranges app
# windows, and runs swaybg.

{ pkgs, niriPackage, ... }:

let
  # Use the same cached package as the running compositor so IPC cannot drift.
  niri = niriPackage;

  # Systemd's user-manager environment can retain a stale socket from an older
  # Niri session. Both scripts locate a socket belonging to a live Niri PID and
  # validate it before issuing IPC requests.
  niriSocketDiscovery = ''
    use_live_niri_socket() {
      local pid socket socket_name
      unset NIRI_SOCKET
      for pid in $(${pkgs.procps}/bin/pgrep -u "$(id -u)" -x niri); do
        for socket in "$XDG_RUNTIME_DIR"/niri.*."$pid".sock; do
          [ -S "$socket" ] || continue
          if NIRI_SOCKET="$socket" ${niri}/bin/niri msg version &>/dev/null; then
            export NIRI_SOCKET="$socket"
            socket_name="''${socket##*/niri.}"
            export WAYLAND_DISPLAY="''${socket_name%."$pid".sock}"
            return 0
          fi
        done
      done
      return 1
    }

    wait_for_niri() {
      local i
      for i in $(seq 1 10); do
        use_live_niri_socket && return 0
        sleep 1
      done
      echo "No live niri IPC socket found" >&2
      return 1
    }
  '';

  configureDisplays = pkgs.writeShellScript "configure-displays" ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    ${niriSocketDiscovery}
    wait_for_niri || exit 1

    outputs=$(${niri}/bin/niri msg --json outputs 2>/dev/null)

    # Lid-close suspend can briefly leave Niri with no active output. There is
    # nothing to arrange in that state; a lid-open or topology event will start
    # this service again once an output has a logical geometry.
    if ! ${pkgs.jq}/bin/jq -e \
      'any(to_entries[]; .value.logical != null)' <<<"$outputs" >/dev/null; then
      echo "No active outputs; deferring display reconciliation"
      exit 0
    fi

    focused_window_id=$(
      ${niri}/bin/niri msg --json windows 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused) | .id' \
        | ${pkgs.coreutils}/bin/head -n 1
    )

    # Resolve only active connectors. Niri retains powered-off outputs in IPC
    # with logical=null, so matching the human-readable inventory mistakes a
    # closed laptop panel for an available Slack target.
    active_output_by_model() {
      ${pkgs.jq}/bin/jq -r --arg model "$1" \
        'to_entries[] | select(.value.logical != null and .value.model == $model) | .key' \
        <<<"$outputs" | ${pkgs.coreutils}/bin/head -n 1
    }
    uw=$(active_output_by_model "AW3423DWF")
    aw=$(active_output_by_model "AW2725DF")
    edp=$(active_output_by_model "0x4165")

    window_ids_for_app() {
      local app_id="$1"
      ${niri}/bin/niri msg --json windows 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r --arg app_id "$app_id" \
          '.[] | select(((.app_id // "") | ascii_downcase) == ($app_id | ascii_downcase)) | .id'
    }

    first_window_id_for_app() {
      window_ids_for_app "$1" | ${pkgs.coreutils}/bin/head -n 1
    }

    launch_if_missing() {
      local app_id="$1"
      shift
      if [ -z "$(first_window_id_for_app "$app_id")" ]; then
        ${niri}/bin/niri msg action spawn -- "$@"
      fi
    }

    workspace_exists() {
      local workspace="$1"
      ${niri}/bin/niri msg --json workspaces 2>/dev/null \
        | ${pkgs.jq}/bin/jq -e --arg workspace "$workspace" \
          'any(.[]; .name == $workspace)' >/dev/null
    }

    ensure_named_workspace() {
      local workspace="$1"
      local output="$2"
      local idx
      workspace_exists "$workspace" && return 0

      idx=$(
        ${niri}/bin/niri msg --json workspaces 2>/dev/null \
          | ${pkgs.jq}/bin/jq -r --arg output "$output" \
            '[.[] | select(.output == $output and .name == null and .active_window_id == null) | .idx] | max // empty'
      )
      [ -n "$idx" ] || return 1
      ${niri}/bin/niri msg action focus-monitor "$output"
      ${niri}/bin/niri msg action set-workspace-name \
        --workspace "$idx" "$workspace"
    }

    remove_named_workspace() {
      local workspace="$1"
      if workspace_exists "$workspace"; then
        ${niri}/bin/niri msg action unset-workspace-name "$workspace" || true
      fi
    }

    move_app_to_workspace() {
      local app_id="$1"
      local workspace="$2"
      local id
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        ${niri}/bin/niri msg action move-window-to-workspace \
          --window-id "$id" --focus false "$workspace"
        ${niri}/bin/niri msg action focus-window --id "$id"
        ${niri}/bin/niri msg action move-column-to-last
      done < <(window_ids_for_app "$app_id")
    }

    focus_first_app_window() {
      local id
      id=$(first_window_id_for_app "$1")
      [ -n "$id" ] || return 1
      ${niri}/bin/niri msg action focus-window --id "$id"
    }

    set_app_column_width() {
      focus_first_app_window "$1" || return 0
      ${niri}/bin/niri msg action set-column-width "$2"
    }

    set_app_window_height() {
      local id
      id=$(first_window_id_for_app "$1")
      [ -n "$id" ] || return 0
      ${niri}/bin/niri msg action set-window-height --id "$id" "$2"
    }

    arrange_docked() {
      ensure_named_workspace "notes" "$aw"
      ensure_named_workspace "media" "$aw"
      ensure_named_workspace "web" "$uw"
      ensure_named_workspace "terminal" "$uw"
      [ -z "$edp" ] || ensure_named_workspace "chat" "$edp"
      ensure_named_workspace "layout-staging" "$uw"

      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "notes" "$aw"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "media" "$aw"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "web" "$uw"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "terminal" "$uw"
      [ -z "$edp" ] || ${niri}/bin/niri msg action move-workspace-to-monitor --reference "chat" "$edp"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "layout-staging" "$uw"

      # Build three physical workspace columns: Obsidian above Spotify on the
      # left, Chrome above Ghostty in the center, and Slack on the right.
      move_app_to_workspace "spotify" "layout-staging"
      move_app_to_workspace "md.Obsidian" "layout-staging"
      move_app_to_workspace "google-chrome" "layout-staging"
      move_app_to_workspace "com.mitchellh.ghostty" "layout-staging"
      move_app_to_workspace "slack" "layout-staging"

      move_app_to_workspace "md.Obsidian" "notes"
      move_app_to_workspace "spotify" "media"
      move_app_to_workspace "google-chrome" "web"
      move_app_to_workspace "com.mitchellh.ghostty" "terminal"

      set_app_window_height "md.Obsidian" "100%"
      set_app_window_height "spotify" "100%"
      set_app_window_height "google-chrome" "100%"
      set_app_window_height "com.mitchellh.ghostty" "100%"
      set_app_column_width "md.Obsidian" "100%"
      set_app_column_width "spotify" "100%"
      set_app_column_width "google-chrome" "100%"
      set_app_column_width "com.mitchellh.ghostty" "100%"

      ${niri}/bin/niri msg action move-workspace-to-index --reference "notes" 1
      ${niri}/bin/niri msg action move-workspace-to-index --reference "media" 2
      ${niri}/bin/niri msg action move-workspace-to-index --reference "web" 1
      ${niri}/bin/niri msg action move-workspace-to-index --reference "terminal" 2

      if [ -n "$edp" ]; then
        move_app_to_workspace "slack" "chat"
        set_app_column_width "slack" "100%"
        ${niri}/bin/niri msg action move-workspace-to-index --reference "chat" 1
      else
        move_app_to_workspace "slack" "web"
        set_app_column_width "slack" "100%"
        remove_named_workspace "chat"
      fi
      remove_named_workspace "layout-staging"

      ${niri}/bin/niri msg action focus-workspace "notes" || true
      [ -z "$edp" ] || ${niri}/bin/niri msg action focus-workspace "chat" || true
      ${niri}/bin/niri msg action focus-workspace "web" || true
    }

    arrange_laptop() {
      local output="$edp"
      [ -n "$output" ] || output=$(
        ${niri}/bin/niri msg --json outputs 2>/dev/null \
          | ${pkgs.jq}/bin/jq -r 'to_entries[] | select(.value.logical != null) | .key' \
          | ${pkgs.coreutils}/bin/head -n 1
      )
      [ -n "$output" ] || return 1

      ensure_named_workspace "web" "$output"
      ensure_named_workspace "terminal" "$output"
      ensure_named_workspace "media" "$output"
      ensure_named_workspace "layout-staging" "$output"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "web" "$output"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "terminal" "$output"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "media" "$output"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "layout-staging" "$output"

      # Collapse the three physical workspace columns into the exact laptop
      # representation selected in the overview.
      move_app_to_workspace "spotify" "layout-staging"
      move_app_to_workspace "md.Obsidian" "layout-staging"
      move_app_to_workspace "google-chrome" "layout-staging"
      move_app_to_workspace "com.mitchellh.ghostty" "layout-staging"
      move_app_to_workspace "slack" "layout-staging"

      move_app_to_workspace "spotify" "media"
      move_app_to_workspace "md.Obsidian" "web"
      move_app_to_workspace "google-chrome" "web"
      move_app_to_workspace "slack" "web"
      move_app_to_workspace "com.mitchellh.ghostty" "terminal"

      set_app_window_height "spotify" "100%"
      set_app_window_height "md.Obsidian" "100%"
      set_app_window_height "google-chrome" "100%"
      set_app_window_height "slack" "100%"
      set_app_window_height "com.mitchellh.ghostty" "100%"
      set_app_column_width "spotify" "100%"
      set_app_column_width "md.Obsidian" "100%"
      set_app_column_width "google-chrome" "100%"
      set_app_column_width "slack" "100%"
      set_app_column_width "com.mitchellh.ghostty" "100%"

      ${niri}/bin/niri msg action move-workspace-to-index --reference "media" 1
      ${niri}/bin/niri msg action move-workspace-to-index --reference "web" 2
      ${niri}/bin/niri msg action move-workspace-to-index --reference "terminal" 3
      remove_named_workspace "notes"
      remove_named_workspace "chat"
      remove_named_workspace "layout-staging"

      ${niri}/bin/niri msg action focus-workspace "web" || true
    }

    # Start missing apps before arranging the selected topology.
    launch_if_missing "spotify" spotify
    launch_if_missing "md.Obsidian" obsidian
    launch_if_missing "google-chrome" google-chrome-stable
    launch_if_missing "com.mitchellh.ghostty" ghostty
    launch_if_missing "slack" slack
    sleep 3

    if [ -n "$uw" ] && [ -n "$aw" ]; then
      arrange_docked
    else
      arrange_laptop
    fi

    # Layout operations temporarily move focus. Restore the window that was
    # active before reconciliation instead of imposing an application choice.
    if [ -n "$focused_window_id" ]; then
      ${niri}/bin/niri msg action focus-window --id "$focused_window_id" || true
    fi

    wp="$HOME/.local/share/wallpapers"
    swaybg_args=()
    [ -z "$uw" ] || swaybg_args+=(--output "$uw" --image "$wp/earthrise.JPG" --mode fill)
    [ -z "$aw" ] || swaybg_args+=(--output "$aw" --image "$wp/earthrise.JPG" --mode fill)
    [ -z "$edp" ] || swaybg_args+=(--output "$edp" --image "$wp/earthrise.JPG" --mode fill)

    if [ ''${#swaybg_args[@]} -eq 0 ]; then
      echo "No active outputs found" >&2
      exit 1
    fi

    exec ${pkgs.swaybg}/bin/swaybg "''${swaybg_args[@]}"
  '';

  topologyWatcher = pkgs.writeShellScript "display-topology-watcher" ''
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    ${niriSocketDiscovery}
    wait_for_niri || exit 1

    active_output_signature() {
      ${niri}/bin/niri msg --json outputs 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r \
          '[to_entries[] | select(.value.logical != null) | .key] | sort | join(",")'
    }

    # Let the startup reconciler launch its initial app set before subscribing.
    sleep 10

    declare -A known_windows=()
    last_signature=$(active_output_signature)
    ${niri}/bin/niri msg --json event-stream \
      | while IFS= read -r event; do
          if ${pkgs.jq}/bin/jq -e 'has("WindowsChanged")' <<<"$event" >/dev/null; then
            while IFS= read -r id; do
              [ -z "$id" ] || known_windows["$id"]=1
            done < <(${pkgs.jq}/bin/jq -r '.WindowsChanged.windows[].id' <<<"$event")
            continue
          fi

          if ${pkgs.jq}/bin/jq -e 'has("WindowClosed")' <<<"$event" >/dev/null; then
            id=$(${pkgs.jq}/bin/jq -r '.WindowClosed.id' <<<"$event")
            unset "known_windows[$id]"
            continue
          fi

          if ${pkgs.jq}/bin/jq -e 'has("WindowOpenedOrChanged")' <<<"$event" >/dev/null; then
            id=$(${pkgs.jq}/bin/jq -r '.WindowOpenedOrChanged.window.id' <<<"$event")
            if [ -z "''${known_windows[$id]+present}" ]; then
              known_windows["$id"]=1
              app_id=$(
                ${pkgs.jq}/bin/jq -r \
                  '.WindowOpenedOrChanged.window.app_id // "" | ascii_downcase' \
                  <<<"$event"
              )
              case "$app_id" in
                spotify|md.obsidian|google-chrome|com.mitchellh.ghostty|slack)
                  ${pkgs.systemd}/bin/systemctl --user --no-block \
                    restart configure-displays.service
                  ;;
              esac
            fi
            continue
          fi

          if ${pkgs.jq}/bin/jq -e 'has("WorkspacesChanged")' <<<"$event" >/dev/null; then
            sleep 0.5
            signature=$(active_output_signature)
            if [ "$signature" != "$last_signature" ]; then
              last_signature="$signature"
              ${pkgs.systemd}/bin/systemctl --user --no-block \
                restart configure-displays.service
            fi
          fi
        done
  '';
in
{
  systemd.user.services = {
    configure-displays = {
      Unit = {
        Description = "Set wallpapers and reconcile app layout";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 30;
        StartLimitBurst = 6;
      };
      Service = {
        Type = "simple";
        ExecStart = "${configureDisplays}";
        Restart = "on-failure";
        RestartSec = "2";
        Environment = "WAYLAND_DISPLAY=wayland-1";
        # Restarts must also terminate in-flight sleeps and Niri/jq IPC calls.
        # At steady state swaybg is the main process, so control-group cleanup
        # preserves no child that should outlive the service.
        KillMode = "control-group";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    display-topology-watcher = {
      Unit = {
        Description = "Reconcile app layout when Niri outputs change";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${topologyWatcher}";
        Restart = "always";
        RestartSec = "2";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
