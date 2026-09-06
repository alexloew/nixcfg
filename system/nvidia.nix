# NVIDIA Graphics Configuration
# The nixos-hardware P16s Gen 3 profile owns the Meteor Lake + RTX 500 Ada
# driver, open-module, PRIME offload, and PCI bus-ID defaults. Keep only local
# graphics policy and suspend/runtime power management here.

{ ... }:

{
  hardware.graphics.enable = true;

  hardware.nvidia.powerManagement = {
    # Preserve VRAM across suspend to prevent graphical corruption on resume.
    enable = true;
    # Power off the PRIME-offload dGPU while it is idle.
    finegrained = true;
  };

  # GPU-specific offload variables are supplied by the nvidia-offload command.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
