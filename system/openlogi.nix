# OpenLogi Logitech HID++ device manager

{ inputs, ... }:

{
  imports = [
    inputs.openlogi.nixosModules.default
  ];

  programs.openlogi = {
    enable = true;
    launchAtLogin = true;
  };
}
