# NVIDIA Graphics Configuration
# Hybrid Intel + NVIDIA laptop (PRIME offload mode)
# Uses Intel for display, NVIDIA for demanding workloads

{ config, pkgs, ... }:

{
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use the stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Power management (helps with laptop battery)
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # Use open source kernel module (for Turing+ GPUs, i.e. RTX 20xx and newer)
    # Set to false if you have an older GPU
    open = true;

    # PRIME hybrid graphics (Intel + NVIDIA)
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Provides `nvidia-offload` command
      };

      # Bus IDs - find yours with: lspci | grep -E 'VGA|3D'
      # Format: PCI:x:y:z
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Environment variables for Wayland + NVIDIA (offload mode)
  # In offload mode Intel drives the display; only set vars that are safe globally.
  # NVIDIA-specific vars (__GLX_VENDOR_LIBRARY_NAME, GBM_BACKEND) are set by
  # the nvidia-offload command when explicitly running apps on the dGPU.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
