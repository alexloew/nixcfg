# Network Configuration
# NetworkManager and related settings

{ config, pkgs, ... }:

{
  # NetworkManager for network management
  networking.networkmanager.enable = true;

  # Firewall (uncomment to configure)
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;

  # OpenSSH (uncomment to enable)
  # services.openssh.enable = true;
}
