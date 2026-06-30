# Tailscale
# WireGuard-based mesh VPN. This enables the tailscaled daemon and installs the
# CLI; authenticate once on the host with `sudo tailscale up`.
# See https://nixos.wiki/wiki/Tailscale

{ ... }:

{
  services.tailscale = {
    enable = true;

    # "client" enables the IP-forwarding sysctls needed to accept subnet routes
    # and use exit nodes. Switch to "server" if this host advertises routes.
    useRoutingFeatures = "client";
  };

  # Trust the tailnet interface so peers can reach this host, and relax
  # reverse-path filtering (required when using exit nodes / subnet routers).
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose";
  };
}
