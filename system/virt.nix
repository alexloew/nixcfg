# Virtualization
# libvirt/QEMU/KVM for running and testing NixOS ISOs

{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;  # Software TPM for VMs
    };
  };

  # Ensure swtpm CA state directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/swtpm-localca 0755 root root -"
  ];

  # virt-manager GUI
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    spice-gtk     # USB redirection and clipboard sharing
  ];
}
