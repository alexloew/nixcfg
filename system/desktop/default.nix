# Desktop Environments - Aggregator
# Display servers and desktop environment configurations
# GNOME provides GDM login, Hyprland provides the compositor for DMS

{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./gnome.nix
    ./hyprland.nix
  ];
}
