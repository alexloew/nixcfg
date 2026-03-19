# Display configuration service
# Detects connected outputs by EDID, applies modes/positions via `niri msg output`,
# and runs swaybg for wallpapers. Triggered at login, on DRM hotplug, and after resume.
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

    if [ -n "$uw" ] && [ -n "$aw" ]; then
      # Dual: 27-inch left at 0,0 — ultrawide right at 2560,0
      # Positions are set statically in niri.nix; only mode needs dynamic override
      ${pkgs.niri}/bin/niri msg output "$aw" mode 2560x1440@143.969
      ${pkgs.niri}/bin/niri msg output "$uw" mode 3440x1440@99.982
      swaybg_args+=(--output "$uw" --image "$wp/kcd2-shepherd-wallpaper-ultrawide.jpg" --mode fill)
      swaybg_args+=(--output "$aw" --image "$wp/kcd2-shepherd.jpg" --mode fill)
    elif [ -n "$uw" ]; then
      # Ultrawide only (lid closed / 27-inch disconnected)
      ${pkgs.niri}/bin/niri msg output "$uw" mode 3440x1440@99.982
      swaybg_args+=(--output "$uw" --image "$wp/kcd2-shepherd-wallpaper-ultrawide.jpg" --mode fill)
    elif [ -n "$aw" ]; then
      # 27-inch only
      ${pkgs.niri}/bin/niri msg output "$aw" mode 2560x1440@143.969
      swaybg_args+=(--output "$aw" --image "$wp/kcd2-shepherd.jpg" --mode fill)
    fi

    [ -n "$edp" ] && swaybg_args+=(--output "$edp" --image "$wp/kcd2-shepherd.jpg" --mode fill)

    if [ ''${#swaybg_args[@]} -eq 0 ]; then
      echo "No outputs found — niri not ready" >&2
      exit 1
    fi

    # Launch apps only on first run (not on resume/hotplug restarts)
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
      Description = "Configure display modes, positions, and wallpapers";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
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
