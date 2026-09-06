# System Modules - Aggregator
# This is the main branch for all NixOS system-level configuration.
# Each sub-module handles a specific concern.

{ config, pkgs, ... }:

{
  imports = [
    ./boot.nix
    ./containers.nix
    ./desktop
    ./hardware.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./nvidia.nix
    ./openlogi.nix
    ./tailscale.nix
    ./users.nix
    ./virt.nix
  ];
}
