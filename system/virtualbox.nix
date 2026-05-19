# VirtualBox
# Oracle VirtualBox hypervisor for running guest VMs.
# See https://nixos.wiki/wiki/VirtualBox

{ config, pkgs, ... }:

{
  virtualisation.virtualbox.host = {
    enable = true;

    # Oracle Extension Pack adds USB 2.0/3.0, RDP, PXE boot, and disk
    # encryption. Unfree (PUEL) and built from source, so rebuilds are slow.
    enableExtensionPack = true;
  };

  # USB passthrough and access to /dev/vboxdrv require membership in vboxusers.
  users.extraGroups.vboxusers.members = [ "alexloewenthal" ];

  # Kernel modules ship with the VirtualBox host package; nothing extra to load.
}
