# Display configuration service
# Detects connected outputs by EDID, applies modes via `niri msg output`,
# and launches apps on first login. Triggered at login, on DRM hotplug, and after resume.

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

    # Wallpaper — set on all outputs regardless of which are connected
    wp="$HOME/.local/share/wallpapers/earthrise.JPG"
    pkill -x swaybg 2>/dev/null || true
    ${pkgs.swaybg}/bin/swaybg --image "$wp" --mode fill &

    # External display mode config — skip if no external monitors connected
    if [ -z "$uw" ] && [ -z "$aw" ]; then
      exit 0
    fi

    # Apply modes
    if [ -n "$uw" ] && [ -n "$aw" ]; then
      ${pkgs.niri}/bin/niri msg output "$aw" mode 2560x1440@143.969
      ${pkgs.niri}/bin/niri msg output "$uw" mode 3440x1440@99.982
    elif [ -n "$uw" ]; then
      ${pkgs.niri}/bin/niri msg output "$uw" mode 3440x1440@99.982
    elif [ -n "$aw" ]; then
      ${pkgs.niri}/bin/niri msg output "$aw" mode 2560x1440@143.969
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
      Type = "oneshot";
      ExecStart = "${configureDisplays}";
      Restart = "on-failure";
      RestartSec = "2";
      Environment = "WAYLAND_DISPLAY=wayland-1";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
