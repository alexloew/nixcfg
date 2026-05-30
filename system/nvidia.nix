# NVIDIA Graphics Configuration
# Hybrid Intel (Meteor Lake-P) + NVIDIA RTX 500 Ada laptop
# PRIME offload mode: Intel drives display, NVIDIA available on demand via nvidia-offload

{ config, pkgs, lib, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # modesetting for the Intel iGPU + nvidia for the dGPU
  # Both are needed for offload mode so the iGPU drives the display
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    # Pin the driver to 595.58.03 (built against the current kernel via mkDriver).
    # NVIDIA 595.71.05 — which nixpkgs nvidiaPackages.{production,stable,latest}
    # now points to — hangs this Meteor Lake + RTX 500 Ada laptop at a frozen
    # cursor before console handoff. The hang tracks the driver, not the kernel:
    # 595.58.03 boots on both 6.18.26 and 6.12.85, while 595.71.05 hangs on both
    # 6.18.33 and 6.12.91. Hashes copied from nixpkgs production at rev 15f4ee45.
    # Revisit when a newer driver boots; then drop back to nvidiaPackages.stable.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.58.03";
      sha256_64bit = "sha256-jA1Plnt5MsSrVxQnKu6BAzkrCnAskq+lVRdtNiBYKfk=";
      sha256_aarch64 = "sha256-hzzIKY1Te8QkCBWR+H5k1FB/HK1UgGhai6cl3wEaPT8=";
      openSha256 = "sha256-6LvJyT0cMXGS290Dh8hd9rc+nYZqBzDIlItOFk8S4n8=";
      settingsSha256 = "sha256-2vLF5Evl2D6tRQJo0uUyY3tpWqjvJQ0/Rpxan3NOD3c=";
      persistencedSha256 = "sha256-AtjM/ml/ngZil8DMYNH+P111ohuk9mWw5t4z7CHjPWw=";
    };
    modesetting.enable = true;
    nvidiaSettings = true;

    # NVIDIA open kernel module (recommended for Turing+ / Ada Lovelace)
    # https://download.nvidia.com/XFree86/Linux-x86_64/565.77/README/kernel_open.html
    open = true;

    # Save VRAM state on suspend to prevent graphical corruption on resume
    powerManagement.enable = true;
    # Fine-grained power management: turns off dGPU when idle (Turing+)
    powerManagement.finegrained = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # Intel Meteor Lake-P [Intel Arc Graphics] / NVIDIA AD107GLM [RTX 500 Ada]
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Prevent nouveau from interfering with the proprietary driver
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  # Environment variables for Wayland + NVIDIA (offload mode)
  # GPU-specific vars (__GLX_VENDOR_LIBRARY_NAME, GBM_BACKEND) are set
  # automatically by the nvidia-offload command for on-demand dGPU use.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
