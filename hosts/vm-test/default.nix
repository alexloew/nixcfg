# Host: vm-test
# Minimal NixOS VM configuration for testing ISOs and system changes.
# Usage:
#   nixos-rebuild build-vm --flake .#vm-test
#   OR build an ISO:
#   nix build .#nixosConfigurations.vm-test.config.system.build.isoImage

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../system/locale.nix
    ../../system/nix.nix
  ];

  # VM-specific hardware
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  networking.hostName = "vm-test";

  # Lightweight user for testing
  users.users.test = {
    isNormalUser = true;
    initialPassword = "test";
    extraGroups = [ "wheel" ];
  };

  # Useful packages for ISO testing
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  # Enable SSH for easy access from host
  services.openssh.enable = true;

  # QEMU guest agent for virt-manager integration
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  system.stateVersion = "25.11";
}
