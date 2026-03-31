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

  # Ensure swtpm directories exist before swtpm_setup runs
  systemd.tmpfiles.rules = [
    "d /var/lib/swtpm-localca          0755 root root -"
    "d /var/lib/libvirt/swtpm          0755 root root -"
    "d /var/log/swtpm                  0755 root root -"
    "d /var/log/swtpm/libvirt          0755 root root -"
    "d /var/log/swtpm/libvirt/qemu     0755 root root -"
  ];

  # virt-manager GUI
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    spice-gtk     # USB redirection and clipboard sharing
  ];
}
