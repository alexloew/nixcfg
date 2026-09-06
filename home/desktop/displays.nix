# Display wallpaper + first-login app-launch service.
#
# Modes/positions/scale are NOT set here — niri applies them natively from its
# own output config (home/desktop/niri.nix) whenever an output connects. This
# service only (a) maps each connected EDID model to its niri connector name,
# (b) launches missing startup apps whose named-workspace rules live in niri.nix,
# and (c) execs swaybg for wallpapers. It issues NO `niri msg output … mode …`, so
# it cannot emit a KMS modeset and therefore cannot self-trigger the DRM
# `change` uevent → restart loop that livelocked boot (issue #111).
#
# It is started once by graphical-session.target. It is no longer wired to a
# DRM-hotplug udev rule (that rule is removed in system/hardware.nix) — the only
# thing real hotplug would re-do here is wallpaper, and niri handles the modes.
#
# Type=simple: swaybg becomes the service process so it persists.
# Restart=on-failure: retries if niri isn't ready yet at startup.

{ pkgs, niriPackage, ... }:

let
  # Use the same cached nixpkgs build as the running compositor so the
  # `niri msg` client cannot drift from the compositor's IPC.
  niri = niriPackage;

  configureDisplays = pkgs.writeShellScript "configure-displays" ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    # Wait for niri to be ready (up to 10 seconds)
    for i in $(seq 1 10); do
      ${niri}/bin/niri msg outputs &>/dev/null && break
      sleep 1
    done

    outputs=$(${niri}/bin/niri msg outputs 2>/dev/null)

    # Extract connector names by model
    uw=$(echo  "$outputs" | grep "AW3423DWF" | awk -F'[()]' '{print $2}')  # ultrawide 3440
    aw=$(echo  "$outputs" | grep "AW2725DF"  | awk -F'[()]' '{print $2}')  # 27-inch 2560
    edp=$(echo "$outputs" | grep "Samsung"   | awk -F'[()]' '{print $2}')  # laptop

    wp="$HOME/.local/share/wallpapers"
    swaybg_args=()

    # Modes and positions come from niri's native output config (niri.nix); this
    # only assigns wallpapers per connected output.
    if [ -n "$uw" ]; then
      swaybg_args+=(--output "$uw" --image "$wp/earthrise.JPG" --mode fill)
    fi
    if [ -n "$aw" ]; then
      swaybg_args+=(--output "$aw" --image "$wp/earthrise.JPG" --mode fill)
    fi

    [ -n "$edp" ] && swaybg_args+=(--output "$edp" --image "$wp/earthrise.JPG" --mode fill)

    if [ ''${#swaybg_args[@]} -eq 0 ]; then
      echo "No outputs found — niri not ready" >&2
      exit 1
    fi

    # Launch each missing app once. Niri's named-workspace rules place them and
    # carry those workspaces across output disconnect/reconnect events.
    windows=$(${niri}/bin/niri msg --json windows 2>/dev/null || printf '[]')
    launch_if_missing() {
      local app_id="$1"
      shift
      if ! ${pkgs.jq}/bin/jq -e --arg app_id "$app_id" \
        'any(.[]; .app_id == $app_id)' <<<"$windows" >/dev/null; then
        ${niri}/bin/niri msg action spawn -- "$@"
      fi
    }

    # Launch order preserves the observed media-workspace column order.
    launch_if_missing "spotify" spotify
    launch_if_missing "md.Obsidian" obsidian
    launch_if_missing "google-chrome" google-chrome-stable
    launch_if_missing "com.mitchellh.ghostty" ghostty
    launch_if_missing "slack" slack

    # Let windows match their rules, then apply the current lid state. This
    # also handles sessions that start while already docked with the lid shut.
    sleep 3
    ${pkgs.systemd}/bin/systemctl --user start --no-block lid-handler.service
    ${niri}/bin/niri msg action focus-workspace "web" || true

    exec ${pkgs.swaybg}/bin/swaybg "''${swaybg_args[@]}"
  '';
in
{
  systemd.user.services.configure-displays = {
    Unit = {
      Description = "Set wallpapers and launch first-login apps";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      # Defensive backstop: this service no longer issues KMS modesets, so the
      # DRM-uevent self-trigger loop is gone — but keep a restart cap so any
      # future regression refuses to runaway-cycle instead of hanging boot.
      StartLimitIntervalSec = 30;
      StartLimitBurst = 6;
    };
    Service = {
      Type = "simple";
      ExecStart = "${configureDisplays}";
      Restart = "on-failure";
      RestartSec = "2";
      Environment = "WAYLAND_DISPLAY=wayland-1";
      KillMode = "process";  # only kill swaybg on restart; leave spawned apps running
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
