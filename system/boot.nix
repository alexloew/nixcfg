# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel rides the nixpkgs-unstable default. The #111 boot livelock was never
  # the kernel — #118 proved it (gen 196 and gen 205 share the IDENTICAL 6.12.85
  # store path, yet 196 boots and 205 hangs). The real causes were userspace: the
  # configure-displays/drm-uevent self-trigger storm (removed in #119) and the
  # GDM-50 greeter ENOENT (replaced by the DMS/greetd greeter in #121). With those
  # fixed, the goodkernel pin (#117) and its nixpkgs-goodkernel flake input are
  # dropped so the kernel tracks the rest of the tree again.

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
