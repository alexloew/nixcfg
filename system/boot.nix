# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, inputs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Background: this Meteor Lake (Core Ultra 7 165H, model 170 stepping 4)
  # laptop hangs at boot — black screen, lone cursor, no console output — on
  # every build from the nixpkgs 20260523 bump, regardless of kernel
  # (6.12.91 / 6.18.33) or NVIDIA driver (pinning 595.58.03 did not help).
  # All 20260430 builds boot. `nomodeset` did not help, so the hang is
  # pre-console, not a GPU issue.
  #
  # Ruled out so far (held constant below): microcode-intel — disabling the
  # initrd late-load did NOT fix the hang. Kept off as the held-constant
  # baseline for this test, so only one variable (the kernel) changes.
  hardware.cpu.intel.updateMicrocode = false;

  # TEST: pin the kernel to the 04-30 tree's 6.18.26 while keeping the rest of
  # the system on the current 05-23 tree. Same diff across two unrelated kernel
  # series (6.12.85->6.12.91, 6.18.26->6.18.33 all hang at the newer patch)
  # points to a stable-tree regression backported to both — the strongest
  # remaining suspect for a pre-console, nomodeset-immune, microcode-immune
  # hang. nvidiaPackages.mkDriver (system/nvidia.nix) rebuilds against this
  # kernel; the pinned 595.58.03 hashes already came from this 04-30 tree.
  # If this boots, the kernel patch bump is confirmed as the culprit.
  boot.kernelPackages =
    (import inputs.nixpkgs-goodkernel {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (pkgs) config;
    }).linuxPackages;

  # DIAGNOSTIC (issue #111): the kernel pin above still hangs with no console
  # output, which exonerates the kernel — the identical 6.18.26 binary boots on
  # the 04-30 tree. We are now flying blind, so this run trades the silent hang
  # for maximum early-boot verbosity to capture the last line before it dies (or
  # to prove there is *no* kernel output at all, which would localize the hang
  # pre-kernel: bootloader / EFI stub / firmware handoff).
  #   - earlycon=efifb + earlyprintk=efi,keep + keep_bootcon: drive the EFI
  #     framebuffer as a console from the earliest possible moment and keep it
  #     after the real console comes up, so pre-fbcon messages are visible.
  #   - ignore_loglevel / loglevel=7 / consoleLogLevel: print everything.
  #   - rd.systemd.show_status + systemd.log_level=debug + log_target=kmsg:
  #     this uses systemd-in-initrd (below), so route its debug to the ring
  #     buffer/console too.
  # This changes only verbosity, not the (known-hanging) baseline. Revert once
  # the hang is localized.
  boot.consoleLogLevel = 7;
  boot.initrd.verbose = true;
  boot.kernelParams = [
    "earlycon=efifb"
    "earlyprintk=efi,keep"
    "keep_bootcon"
    "ignore_loglevel"
    "loglevel=7"
    "rd.systemd.show_status=true"
    "systemd.log_level=debug"
    "systemd.log_target=kmsg"
    "udev.log_level=info"
  ];

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
