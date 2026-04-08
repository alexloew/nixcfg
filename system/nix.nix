# Nix Configuration
# Nix daemon and nixpkgs settings

{ config, pkgs, ... }:

{
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Stub missing packages referenced by upstream modules until they land in nixpkgs
  nixpkgs.overlays = [
    # nflx-nixcfg/modules/ai.nix references opencode-desktop which is not yet in nixpkgs
    (final: prev: {
      opencode-desktop = prev.opencode;
    })
  ];

  # System state version - DO NOT CHANGE without reading the docs
  system.stateVersion = "25.11";
}
