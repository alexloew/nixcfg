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

  # Detects current connector names by EDID and sets wallpapers via swaybg.
  # Uses text output of `niri msg outputs` — more stable across niri versions.
  wallpaperScript = pkgs.writeShellScript "set-wallpapers" ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

    pkill swaybg 2>/dev/null || true
    sleep 1

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

    [ ''${#args[@]} -gt 0 ] && nohup ${pkgs.swaybg}/bin/swaybg "''${args[@]}" >/dev/null 2>&1 &
  '';
in
{
  # Systemd user service — started at login, restartable after resume/profile switch
  systemd.user.services.set-wallpapers = {
    Unit = {
      Description = "Set per-output wallpapers";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperScript}";
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
