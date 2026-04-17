# Kanshi — dynamic output configuration
# Uses EDID (make/model/serial) so connector name swaps after NVIDIA resume
# don't break the layout. Reapplies config on every output change.

{ ... }:

let
  ultrawide = "Dell Inc. AW3423DWF GF0C2S3";  # 3440x1440 — right
  alienware  = "Dell Inc. AW2725DF 92Q6ZZ3";   # 2560x1440 — left
  laptop     = "Samsung Display Corp. 0x4165 Unknown";
in
{
  services.kanshi = {
    enable = true;

    settings = [
      # Dual-monitor: 27-inch left, ultrawide right
      {
        profile.name = "dual";
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
