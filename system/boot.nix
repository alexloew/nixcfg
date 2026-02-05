# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS unlock for swap partition
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52".device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
}
