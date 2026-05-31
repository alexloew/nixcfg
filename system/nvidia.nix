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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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
