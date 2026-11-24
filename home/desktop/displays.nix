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

  displayLayoutHelpers = ''
    niri_json() { ${pkgs.coreutils}/bin/timeout 5s ${niri}/bin/niri msg --json "$@"; }
    layout_jq() { ${pkgs.jq}/bin/jq "$@"; }
    layout_flock() { ${pkgs.util-linux}/bin/flock "$@"; }
    layout_service_is_running() {
      ${pkgs.systemd}/bin/systemctl --user is-active --quiet configure-displays.service
    }
    request_layout_reconciliation() {
      ${pkgs.systemd}/bin/systemctl --user --no-block restart configure-displays.service
    }
    ${builtins.readFile ./display-layout.sh}
  '';

  configureDisplays = pkgs.writeShellScript "configure-displays" ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    ${niriSocketDiscovery}
    wait_for_niri || exit 1

    ${displayLayoutHelpers}
    exec 9>"$XDG_RUNTIME_DIR/nixcfg-display-layout.lock"
    layout_flock -x 9 || exit 1
    # Do not launch applications while suspend leaves us without a display.
    # This is only an early guard; resample after startup before moving anything.
    read_layout_outputs || exit 75
    if [ "$expected_workspaces" = '{}' ]; then
      echo "No active outputs; deferring display reconciliation"
      exit 0
    fi

    focused_window_id=$(
      ${niri}/bin/niri msg --json windows 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused) | .id' \
        | ${pkgs.coreutils}/bin/head -n 1
    )

    window_ids_for_app() {
      local app_id="$1"
      ${niri}/bin/niri msg --json windows 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r --arg app_id "$app_id" \
          'def canonical_app_id:
             ascii_downcase | if . == "md.obsidian.obsidian" then "md.obsidian" else . end;
           .[] | select(((.app_id // "") | canonical_app_id) == ($app_id | canonical_app_id)) | .id'
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
      ensure_named_workspace "chat" "$aw"
      ensure_named_workspace "media" "$aw"
      ensure_named_workspace "web" "$uw"
      ensure_named_workspace "terminal" "$uw"
      [ -z "$edp" ] || ensure_named_workspace "notes" "$edp"
      ensure_named_workspace "layout-staging" "$uw"

      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "chat" "$aw"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "media" "$aw"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "web" "$uw"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "terminal" "$uw"
      [ -z "$edp" ] || ${niri}/bin/niri msg action move-workspace-to-monitor --reference "notes" "$edp"
      ${niri}/bin/niri msg action move-workspace-to-monitor --reference "layout-staging" "$uw"

      # Build three physical workspace columns: Chrome above Herdr Desktop on
      # the left, Slack above Spotify in the center, and Obsidian on the laptop.
      move_app_to_workspace "spotify" "layout-staging"
      move_app_to_workspace "md.Obsidian" "layout-staging"
      move_app_to_workspace "google-chrome" "layout-staging"
      move_app_to_workspace "herdr-app" "layout-staging"
      move_app_to_workspace "slack" "layout-staging"

      move_app_to_workspace "slack" "chat"
      move_app_to_workspace "spotify" "media"
      move_app_to_workspace "google-chrome" "web"
      move_app_to_workspace "herdr-app" "terminal"

      set_app_window_height "slack" "100%"
      set_app_window_height "spotify" "100%"
      set_app_window_height "google-chrome" "100%"
      set_app_window_height "herdr-app" "100%"
      set_app_column_width "slack" "100%"
      set_app_column_width "spotify" "100%"
      set_app_column_width "google-chrome" "100%"
      set_app_column_width "herdr-app" "100%"

      ${niri}/bin/niri msg action move-workspace-to-index --reference "chat" 1
      ${niri}/bin/niri msg action move-workspace-to-index --reference "media" 2
      ${niri}/bin/niri msg action move-workspace-to-index --reference "web" 1
      ${niri}/bin/niri msg action move-workspace-to-index --reference "terminal" 2

      if [ -n "$edp" ]; then
        move_app_to_workspace "md.Obsidian" "notes"
        ${niri}/bin/niri msg action move-workspace-to-index --reference "notes" 1
      else
        move_app_to_workspace "md.Obsidian" "web"
        remove_named_workspace "notes"
      fi
      set_app_window_height "md.Obsidian" "100%"
      set_app_column_width "md.Obsidian" "100%"
      remove_named_workspace "layout-staging"

      ${niri}/bin/niri msg action focus-workspace "chat" || true
      [ -z "$edp" ] || ${niri}/bin/niri msg action focus-workspace "notes" || true
      ${niri}/bin/niri msg action focus-workspace "web" || true
    }

    arrange_laptop() {
      local output="$fallback_output"
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
      move_app_to_workspace "herdr-app" "layout-staging"
      move_app_to_workspace "slack" "layout-staging"

      move_app_to_workspace "spotify" "media"
      move_app_to_workspace "md.Obsidian" "web"
      move_app_to_workspace "google-chrome" "web"
      move_app_to_workspace "slack" "web"
      move_app_to_workspace "herdr-app" "terminal"

      set_app_window_height "spotify" "100%"
      set_app_window_height "md.Obsidian" "100%"
      set_app_window_height "google-chrome" "100%"
      set_app_window_height "slack" "100%"
      set_app_window_height "herdr-app" "100%"
      set_app_column_width "spotify" "100%"
      set_app_column_width "md.Obsidian" "100%"
      set_app_column_width "google-chrome" "100%"
      set_app_column_width "slack" "100%"
      set_app_column_width "herdr-app" "100%"

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
    launch_if_missing "herdr-app" herdr-app
    launch_if_missing "slack" slack
    sleep 3

    # Sample after application startup, not before the three-second delay.
    reconcile_display_layout
    layout_result=$?
    case "$layout_result" in
      0) ;;
      2) exit 0 ;; # No active outputs during suspend; the watcher will retry.
      *) exit "$layout_result" ;;
    esac

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

    # Do not let the long-lived wallpaper process retain the layout lock.
    layout_flock -u 9
    exec 9>&-
    exec ${pkgs.swaybg}/bin/swaybg "''${swaybg_args[@]}"
  '';

  topologyWatcher = pkgs.writeShellScript "display-topology-watcher" ''
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    ${niriSocketDiscovery}
    wait_for_niri || exit 1
    ${displayLayoutHelpers}
    exec 9>"$XDG_RUNTIME_DIR/nixcfg-display-layout.lock"
    watch_display_layout
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
        # Layout verification has its own bounded retry budget; do not turn a
        # persistent mismatch into an unlimited systemd restart cycle.
        RestartPreventExitStatus = [ 75 ];
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
