# Desktop Environments - Aggregator
# Display servers and desktop environment configurations
# GNOME provides GDM login, Niri provides the compositor for DMS

{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./gnome.nix
    ./niri.nix
  ];
}
