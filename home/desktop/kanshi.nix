# Kanshi — dynamic output configuration
# Uses EDID (make/model/serial) so connector name swaps after NVIDIA resume
# don't break the layout. Reapplies config on every output change.
#
# Wallpapers are managed by the set-wallpapers systemd user service below.
# Kanshi triggers a restart of that service via exec after each profile switch.

{ pkgs, ... }:

let
  ultrawide = "Dell Inc. AW3423DWF GF0C2S3";  # 3440x1440 — right
  alienware  = "Dell Inc. AW2725DF 92Q6ZZ3";   # 2560x1440 — left
  laptop     = "Samsung Display Corp. 0x4165 Unknown";

  # Detects connector names by EDID and execs swaybg as the service process.
  # Type=simple keeps swaybg running; restarting the service replaces it cleanly.
  # Exits 1 if niri isn't ready yet — Restart=on-failure will retry.
  wallpaperScript = pkgs.writeShellScript "set-wallpapers" ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    outputs=$(${pkgs.niri}/bin/niri msg outputs 2>/dev/null)

    # Extract connector name from: Output "Dell Inc. AW3423DWF GF0C2S3" (DP-2)
    uw=$(echo  "$outputs" | grep "AW3423DWF" | awk -F'[()]' '{print $2}')
    aw=$(echo  "$outputs" | grep "AW2725DF"  | awk -F'[()]' '{print $2}')
    edp=$(echo "$outputs" | grep "Samsung"   | awk -F'[()]' '{print $2}')

    wp="$HOME/.local/share/wallpapers"
    args=()
    [ -n "$uw"  ] && args+=(--output "$uw"  --image "$wp/kcd2-shepherd-wallpaper-ultrawide.jpg" --mode fill)
    [ -n "$aw"  ] && args+=(--output "$aw"  --image "$wp/kcd2-shepherd.jpg" --mode fill)
    [ -n "$edp" ] && args+=(--output "$edp" --image "$wp/kcd2-shepherd.jpg" --mode fill)

    if [ ''${#args[@]} -eq 0 ]; then
      echo "No outputs found — niri not ready yet" >&2
      exit 1
    fi

    exec ${pkgs.swaybg}/bin/swaybg "''${args[@]}"
  '';
in
{
  # Wallpaper service — Type=simple so swaybg IS the service process.
  # Restartable by kanshi exec and after resume via powerManagement.resumeCommands.
  systemd.user.services.set-wallpapers = {
    Unit = {
      Description = "Set per-output wallpapers";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${wallpaperScript}";
      Restart = "on-failure";
      RestartSec = "2";
      Environment = "WAYLAND_DISPLAY=wayland-1";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  services.kanshi = {
    enable = true;

    settings = [
      # Dual-monitor: 27-inch left, ultrawide right
      {
        profile.name = "dual";
        profile.exec = [ "${pkgs.systemd}/bin/systemctl --user restart set-wallpapers.service" ];
        profile.outputs = [
          {
            criteria = alienware;
            mode = "2560x1440@143.969";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = ultrawide;
            mode = "3440x1440@99.982";
            position = "2560,0";
            scale = 1.0;
          }
        ];
      }

      # Laptop only (lid open, no externals)
      {
        profile.name = "laptop";
        profile.exec = [ "${pkgs.systemd}/bin/systemctl --user restart set-wallpapers.service" ];
        profile.outputs = [
          {
            criteria = laptop;
            scale = 2.0;
          }
        ];
      }

      # Ultrawide only (lid closed)
      {
        profile.name = "ultrawide-only";
        profile.exec = [ "${pkgs.systemd}/bin/systemctl --user restart set-wallpapers.service" ];
        profile.outputs = [
          {
            criteria = ultrawide;
            mode = "3440x1440@99.982";
            position = "0,0";
            scale = 1.0;
          }
        ];
      }
    ];
  };
}
