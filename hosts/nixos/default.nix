# Host: nixos
# This is the entry point for host-specific system configuration.
# It imports hardware config and delegates to system modules.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../system
  ];

  # Host-specific overrides go here
  networking.hostName = "nixos";
}
