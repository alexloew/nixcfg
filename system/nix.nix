# Nix Configuration
# Nix daemon and nixpkgs settings

{ config, pkgs, ... }:

{
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version - DO NOT CHANGE without reading the docs
  system.stateVersion = "25.11";
}
