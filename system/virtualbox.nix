# VirtualBox
# Oracle VirtualBox hypervisor for running guest VMs.
# See https://nixos.wiki/wiki/VirtualBox

{ config, pkgs, ... }:

{
  virtualisation.virtualbox.host = {
    enable = true;

    # Oracle Extension Pack adds USB 2.0/3.0, RDP, PXE boot, and disk
    # encryption. It is a separate fixed-output derivation (a fetchurl of
    # Oracle's blob), not part of the host package, so enabling it costs a
    # ~25 MiB download from Oracle rather than a build. cache.nixos.org will
    # not serve it because PUEL is unfree, which is expected, not a problem.
    #
    # When VirtualBox itself compiles for many minutes, the extension pack is
    # not the cause: it means the host package had no cache hit at the current
    # nixpkgs rev. VirtualBox is not a release-critical Hydra job, so a
    # nixos-unstable bump can land before its build is published.
    enableExtensionPack = true;
  };

  # USB passthrough and access to /dev/vboxdrv require membership in vboxusers.
  users.groups.vboxusers.members = [ "alexloewenthal" ];

  # Kernel modules ship with the VirtualBox host package; nothing extra to load.
}
