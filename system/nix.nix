# Nix Configuration
# Nix daemon and nixpkgs settings

{ config, pkgs, pkgs-unstable, ... }:

{
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # opencode-desktop is in nixpkgs-unstable but not yet in the stable channel
  nixpkgs.overlays = [
    # opencode-desktop depends on gh from unstable; align gh to avoid buildEnv conflict
    (_final: _prev: { inherit (pkgs-unstable) opencode-desktop gh; })
  ];

  # System state version - DO NOT CHANGE without reading the docs
  system.stateVersion = "25.11";
}
