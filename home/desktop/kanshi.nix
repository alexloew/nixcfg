# Kanshi — dynamic output configuration
# Uses EDID (make/model/serial) so connector name swaps after NVIDIA resume
# don't break the layout. Reapplies config on every output change.
# Wallpapers are set via exec after each profile activation, using
# `niri msg --json outputs` to find the right connector per display.

{ pkgs, ... }:

let
  ultrawide = "Dell Inc. AW3423DWF GF0C2S3";  # 3440x1440 — right
  alienware  = "Dell Inc. AW2725DF 92Q6ZZ3";   # 2560x1440 — left
  laptop     = "Samsung Display Corp. 0x4165 Unknown";

  wallpaperScript = pkgs.writeShellScript "set-wallpapers" ''
    pkill swaybg 2>/dev/null || true
    sleep 1  # wait for outputs to settle after profile switch

    outputs=$(${pkgs.niri}/bin/niri msg outputs 2>/dev/null)

    # Extract connector name from lines like: Output "Dell Inc. AW3423DWF GF0C2S3" (DP-2)
    uw=$(echo  "$outputs" | grep "AW3423DWF" | awk -F'[()]' '{print $2}')
    aw=$(echo  "$outputs" | grep "AW2725DF"  | awk -F'[()]' '{print $2}')
    edp=$(echo "$outputs" | grep "Samsung"   | awk -F'[()]' '{print $2}')

    wp="$HOME/.local/share/wallpapers"
    args=()
    [ -n "$uw"  ] && args+=(--output "$uw"  --image "$wp/kcd2-shepherd-wallpaper-ultrawide.jpg" --mode fill)
    [ -n "$aw"  ] && args+=(--output "$aw"  --image "$wp/kcd2-shepherd.jpg" --mode fill)
    [ -n "$edp" ] && args+=(--output "$edp" --image "$wp/kcd2-shepherd.jpg" --mode fill)

    # Run swaybg detached so kanshi's exec returns immediately
    [ ''${#args[@]} -gt 0 ] && nohup ${pkgs.swaybg}/bin/swaybg "''${args[@]}" >/dev/null 2>&1 &
  '';
in
{
  services.kanshi = {
    enable = true;

    settings = [
      # Dual-monitor: 27-inch left, ultrawide right
      {
        profile.name = "dual";
        profile.exec = [ "${wallpaperScript}" ];
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
        profile.exec = [ "${wallpaperScript}" ];
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
        profile.exec = [ "${wallpaperScript}" ];
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
