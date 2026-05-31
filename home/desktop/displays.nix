# Display wallpaper + first-login app-launch service.
#
# Modes/positions/scale are NOT set here — niri applies them natively from its
# own output config (home/desktop/niri.nix) whenever an output connects. This
# service only (a) maps each connected EDID model to its niri connector name,
# (b) launches the startup apps on the correct monitors on first login, and
# (c) execs swaybg for wallpapers. It issues NO `niri msg output … mode …`, so
# it cannot emit a KMS modeset and therefore cannot self-trigger the DRM
# `change` uevent → restart loop that livelocked boot (issue #111).
#
# It is started once by graphical-session.target. It is no longer wired to a
# DRM-hotplug udev rule (that rule is removed in system/hardware.nix) — the only
# thing real hotplug would re-do here is wallpaper, and niri handles the modes.
#
# Type=simple: swaybg becomes the service process so it persists.
# Restart=on-failure: retries if niri isn't ready yet at startup.

{ pkgs, ... }:

let
  configureDisplays = pkgs.writeShellScript "configure-displays" ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    # Wait for niri to be ready (up to 10 seconds)
    for i in $(seq 1 10); do
      ${pkgs.niri}/bin/niri msg outputs &>/dev/null && break
      sleep 1
    done

    outputs=$(${pkgs.niri}/bin/niri msg outputs 2>/dev/null)

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

    # Launch apps only on first run (not on resume restarts)
    if [ -n "$uw" ] && ! pgrep -f "google-chrome" > /dev/null; then
      # Focus ultrawide — Chrome and Ghostty will open here
      ${pkgs.niri}/bin/niri msg action focus-monitor "$uw"
      sleep 0.5
      # Chrome first → left column; Ghostty second → right column
      # Chrome needs ~2s to create its window; if Ghostty wins the race it ends up left
      ${pkgs.niri}/bin/niri msg action spawn -- google-chrome-stable
      sleep 2
      ${pkgs.niri}/bin/niri msg action spawn -- ghostty
      # Wait for Ghostty to open, then refocus Chrome (left column)
      sleep 1
      ${pkgs.niri}/bin/niri msg action focus-column-left
      # Slack on 27-inch
      if [ -n "$aw" ]; then
        sleep 0.5
        ${pkgs.niri}/bin/niri msg action focus-monitor "$aw"
        sleep 0.5
        ${pkgs.niri}/bin/niri msg action spawn -- slack
      fi
    fi

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
