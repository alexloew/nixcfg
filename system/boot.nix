# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Pin to the 6.12 LTS kernel.
  # The unstable default kernel (6.18.33 as of nixpkgs 64c08a7) hangs at a
  # frozen cursor before console handoff on this Meteor Lake laptop — a regression
  # from the previously-working 6.18.26. 6.12 LTS is mature on Meteor Lake and
  # supported by the NVIDIA 595 open module. Revisit when a newer kernel boots.
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
