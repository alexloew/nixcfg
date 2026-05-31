# Boot Configuration
# Bootloader and early boot settings

{ config, pkgs, inputs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ROOT CAUSE (issue #111): this Meteor Lake (Core Ultra 7 165H) laptop boot-
  # livelocks on kernel 6.18.26 but boots cleanly on 6.12.85. Proven from the
  # persistent journal across 9 boots: every 6.18.26 boot emits ~372 synthetic
  # `change` uevents (systemd-logind re-triggering seat-master DRM nodes) and
  # hangs; every 6.12.85 boot emits 0 and reaches multi-user. On 6.18.26 a
  # `simpledrm` card0 appears as an extra seat-master alongside i915 (card2) and
  # nvidia (card1); logind loops re-triggering synthetic change uevents on the
  # DRM nodes, the udev drm-change rule (system/hardware.nix) restarts
  # configure-displays on each, and PID1 enters a PropertiesChanged storm.
  #
  # PRIOR FALSE TRAILS (all left the kernel pin below pointed at 6.18.26, so they
  # only ever tuned downstream symptoms): #113 verbose run, #114 firmware pin,
  # #115 HOTPLUG gate, #116 idempotent modeset. The single discriminating
  # variable is the kernel: 6.12.85 good, 6.18.26 bad.

  # THE FIX: pin the kernel to 6.12.85 — the exact LTS the known-good 04-30 gen
  # boots. The previous pin took `.linuxPackages` from the 04-30 tree, which is
  # 6.18.26 (the bad kernel) — not 6.12.85. We have NO data on 05-23's 6.12.91,
  # so pin the proven-good 6.12.85 specifically; it (and the nvidia driver built
  # against it) is already in the store, so this is a near-zero rebuild.
  # nvidiaPackages.mkDriver (system/nvidia.nix) rebuilds against this kernel.
  boot.kernelPackages =
    (import inputs.nixpkgs-goodkernel {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (pkgs) config;
    }).linuxPackages_6_12;

  # Modest console verbosity. The heavy diagnostic flags (systemd.log_level=debug,
  # udev.log_level=debug) are dropped now that the cause is known — they slowed
  # boot and added no further signal. A confirming boot just needs to reach
  # multi-user with ~0 configure-displays restarts.
  boot.consoleLogLevel = 7;
  boot.initrd.verbose = true;
  boot.kernelParams = [
    "loglevel=7"
    "rd.systemd.show_status=true"
  ];

  # Use systemd in initrd (required for TPM2-based LUKS unlock)
  boot.initrd.systemd.enable = true;

  # LUKS unlock for swap partition (TPM2 enrolled separately)
  boot.initrd.luks.devices."luks-a974ef85-8d19-4ef1-a7e4-cbdd1637fe52" = {
    device = "/dev/disk/by-uuid/a974ef85-8d19-4ef1-a7e4-cbdd1637fe52";
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
}
