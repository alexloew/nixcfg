# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
