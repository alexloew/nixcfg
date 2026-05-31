# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TEST: disable initrd Intel microcode late-load.
  # This Meteor Lake (Core Ultra 7 165H, model 170 stepping 4) laptop hangs at
  # boot — black screen, lone cursor, no console output — on every build from
  # the nixpkgs 20260523 bump, regardless of kernel (6.12.91 / 6.18.33) or
  # NVIDIA driver (pinning 595.58.03 did not help). All 20260430 builds boot.
  # `nomodeset` did not help, so the hang is pre-console, not a GPU issue.
  # The bump pulls microcode-intel 20260410 -> 20260512, late-loaded in initrd
  # before console handoff — the prime suspect. Booting now isolates microcode.
  # The CPU still gets whatever revision the BIOS applies; we only skip the
  # kernel late-load. If this boots, replace with a pin to the older
  # microcode-intel rather than leaving updates off (keeps security fixes).
  hardware.cpu.intel.updateMicrocode = false;

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
