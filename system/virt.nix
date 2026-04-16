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
    "d /var/lib/swtpm-localca          0750 tss  tss  -"
    "d /var/lib/libvirt/swtpm          0755 root root -"
    "d /var/log/swtpm                  0755 root root -"
    "d /var/log/swtpm/libvirt          0755 root root -"
    "d /var/log/swtpm/libvirt/qemu     0755 root root -"
  ];

  # Allow libvirt NAT network traffic through the firewall.
  # trustedInterfaces covers INPUT; extraCommands covers FORWARD so VM
  # traffic can be routed from virbr0 out to the host's upstream interface.
  networking.firewall.trustedInterfaces = [ "virbr0" ];
  networking.firewall.extraCommands = ''
    iptables -A FORWARD -i virbr0 -j ACCEPT
    iptables -A FORWARD -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    # Clamp TCP MSS to PMTU so VM packets fit through the VPN tunnel (tun0 MTU=1400)
    iptables -t mangle -A FORWARD -i virbr0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    iptables -t mangle -A FORWARD -o virbr0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  '';

  # Required for libvirt NAT networking (VM traffic forwarded to host uplink)
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # virt-manager GUI
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    spice-gtk     # USB redirection and clipboard sharing
  ];
}
