# OpenLogi Logitech HID++ device manager

{ config, inputs, lib, pkgs, ... }:

{
  # OpenLogi creates a virtual input device for button remapping. Loading the
  # module gives udev a real device event on which to apply the upstream
  # active-seat uaccess rule.
  hardware.uinput.enable = true;

  # Let nixpkgs own module integration, but keep the newer upstream package.
  programs.openlogi = {
    enable = true;
    package = inputs.openlogi.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  # The nixpkgs module installs the package and udev rules, but does not start
  # the agent. Preserve the upstream module's launchAtLogin=true behavior.
  systemd.user.services.openlogi-agent = lib.mkIf config.programs.openlogi.enable {
    description = "OpenLogi background agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = lib.getExe' config.programs.openlogi.package "openlogi-agent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
