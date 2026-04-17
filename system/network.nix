# Network Configuration
# NetworkManager and related settings

{ config, pkgs, ... }:

{
  # NetworkManager for network management
  networking.networkmanager.enable = true;
}
