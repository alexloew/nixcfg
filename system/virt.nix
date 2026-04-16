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

  # Bootstrap the default NAT network on first boot (or after /var/lib wipe).
  # libvirtd doesn't auto-create it on NixOS, so we define/start/autostart it
  # idempotently via a oneshot service that runs after libvirtd is ready.
  systemd.services.libvirt-default-network = {
    description = "Bootstrap libvirt default NAT network";
    requires = [ "libvirtd.service" ];
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = let
      virsh = "${pkgs.libvirt}/bin/virsh";
      defaultNetXml = pkgs.writeText "libvirt-default-net.xml" ''
        <network>
          <name>default</name>
          <bridge name="virbr0"/>
          <forward/>
          <ip address="192.168.122.1" netmask="255.255.255.0">
            <dhcp>
              <range start="192.168.122.2" end="192.168.122.254"/>
            </dhcp>
          </ip>
        </network>
      '';
    in ''
      if ! ${virsh} net-list --all | grep -q default; then
        ${virsh} net-define ${defaultNetXml}
        ${virsh} net-autostart default
      fi
      if ! ${virsh} net-list | grep -q "default.*active"; then
        ${virsh} net-start default
      fi
    '';
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
