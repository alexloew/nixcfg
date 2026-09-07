# OpenLogi Logitech HID++ device manager

{ inputs, ... }:

{
  imports = [
    inputs.openlogi.nixosModules.default
  ];

  # OpenLogi creates a virtual input device for button remapping. Loading the
  # module gives udev a real device event on which to apply the upstream
  # active-seat uaccess rule.
  hardware.uinput.enable = true;

  programs.openlogi = {
    enable = true;
    launchAtLogin = true;
  };
}
