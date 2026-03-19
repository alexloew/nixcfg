# Desktop Configuration - Aggregator
# Desktop environment customization and extensions
# DMS + Niri is the primary desktop, GNOME extensions for fallback

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./dms.nix
    ./fonts.nix
    ./gnome.nix
    ./niri.nix
    ./idle.nix
    ./kanshi.nix
  ];
}
