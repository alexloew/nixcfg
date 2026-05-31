# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, inputs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Background: this Meteor Lake (Core Ultra 7 165H, model 170 stepping 4)
  # laptop hangs at boot on every build from the nixpkgs 20260523 bump. The
  # max-verbosity diagnostic run (PR #113) DISPROVED the "pre-console" theory:
  # it showed systemd PID 1 alive in userspace at ~1400s, stuck in an infinite
  # loop of single getgrnam() lookups for device-node groups (render, sgx,
  # audio, lp, disk...) — i.e. udev re-applying device-node ownership over and
  # over, a uevent/probe storm. The varlink GetGroupRecord spam is the symptom;
  # a driver re-probing is the cause. The earlier "black screen, no output" was
  # this same loop with no console configured.
  #
  # Ruled out (held constant below): kernel (pinned good 6.18.26 — still loops),
  # systemd (260.1) and glibc (2.42) — byte-identical across trees, so the
  # userdb code itself is not the bug. microcode-intel — late-load disabled,
  # still hangs. The one untested early-boot delta that fits a probe storm is
  # linux-firmware (20260410 good -> 20260519 bad): a regressed/renamed blob
  # makes a driver fail-probe-loop. THIS TEST pins it to the good tree.
  hardware.cpu.intel.updateMicrocode = false;

  # TEST (issue #111): pin linux-firmware to the known-good 04-30 tree while the
  # rest of the system stays on 05-23. Single changed variable vs the current
  # hanging baseline. If this boots, the firmware bump is confirmed as the
  # culprit and we can unpin the kernel next. Already in the store (good gens
  # used it), so no heavy rebuild.
  nixpkgs.overlays = [
    (final: prev: {
      linux-firmware =
        (import inputs.nixpkgs-goodkernel {
          inherit (prev.stdenv.hostPlatform) system;
          inherit (prev) config;
        }).linux-firmware;
    })
  ];

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

  # DIAGNOSTIC (issue #111): kept on so that if the firmware pin does NOT fix
  # it, the next boot names the culprit. The pre-console theory is dead (boot
  # reaches userspace), so the framebuffer-throttle flags (earlycon=efifb,
  # earlyprintk, keep_bootcon, ignore_loglevel) are dropped — they forced every
  # debug line through the unaccelerated EFI framebuffer at ~120ms/line, turning
  # the loop into a 20-minute crawl with no extra signal. udev.log_level=debug
  # is added so a still-looping boot shows which device is re-probing (the storm
  # source) rather than only the downstream group-lookup spam.
  boot.consoleLogLevel = 7;
  boot.initrd.verbose = true;
  boot.kernelParams = [
    "loglevel=7"
    "rd.systemd.show_status=true"
    "systemd.log_level=debug"
    "systemd.log_target=kmsg"
    "udev.log_level=debug"
  ];

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
