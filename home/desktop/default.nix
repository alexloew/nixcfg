# Desktop Configuration - Aggregator
# Desktop environment customization and extensions
# DMS + Hyprland is the primary desktop, GNOME extensions for fallback

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./hyprland.nix
    ./dms.nix
  ];
}
