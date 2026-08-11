# Nix Configuration
# Nix daemon and nixpkgs settings

{ config, pkgs, ... }:

{
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep the writable Git checkout as the single source of truth. `nh os`
  # commands use this flake instead of the root-owned /etc/nixos directory.
  programs.nh = {
    enable = true;
    flake = "/home/alexloewenthal/gh-personal/nixcfg";
  };

  # Garbage collection. One generation of this system is ~28 GiB, so a handful
  # of untended generations is enough to fill a disk. Determinate manages
  # /etc/nix/nix.conf but not GC on NixOS (its garbageCollector option is
  # nix-darwin only), so the stock NixOS timer is what does the work here.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Hardlink identical files in the store. Cheap dedup on top of GC.
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version - DO NOT CHANGE without reading the docs
  system.stateVersion = "25.11";
}
