# Kanshi — dynamic output configuration
# Identifies displays by EDID (make/model/serial) so connector name swaps
# (common with NVIDIA after resume) don't break the layout.
# Reapplies config on every output change, including wake from sleep.
#
# To get EDID-based criteria, run: niri msg outputs
# Then replace the "DP-*" connector strings below with the
# "Make Model Serial" strings shown for each display.

{ ... }:

{
  services.kanshi = {
    enable = true;

    settings = [
      # Dual-monitor: ultrawide left, 1440p right
      {
        profile.name = "dual";
        profile.outputs = [
          {
            criteria = "DP-1";  # ultrawide — replace with EDID string from `niri msg outputs`
            mode = "3440x1440@99.982";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = "DP-2";  # 1440p — replace with EDID string from `niri msg outputs`
            mode = "2560x1440@143.969";
            position = "3440,0";
            scale = 1.0;
          }
        ];
      }

      # Laptop only (lid open, no externals)
      {
        profile.name = "laptop";
        profile.outputs = [
          {
            criteria = "eDP-1";
            scale = 2.0;
          }
        ];
      }

      # Ultrawide only (lid closed)
      {
        profile.name = "ultrawide-only";
        profile.outputs = [
          {
            criteria = "DP-1";  # replace with EDID string
            mode = "3440x1440@99.982";
            position = "0,0";
            scale = 1.0;
          }
        ];
      }
    ];
  };
}
