# Containers
# Rootless Podman, used as the backend for distrobox (see home/dev/distrobox.nix)

{ config, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;

    # Alias docker -> podman. Nothing here installs real Docker, so the alias
    # is unambiguous and keeps docker-oriented tooling/muscle memory working.
    dockerCompat = true;

    # Container name resolution on podman's default bridge network
    defaultNetwork.settings.dns_enabled = true;

    # Distrobox images are long-lived; only reap dangling layers/build cache.
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--filter" "until=168h" ];
    };
  };

  # Rootless podman relies on subuid/subgid ranges; NixOS allocates these
  # automatically for normal users (users.users.<name>.autoSubUidGidRange).

  # Generates the CDI spec that lets containers use the host NVIDIA driver
  # (`distrobox create --nvidia` / `nvidia=true` in assemble.ini).
  hardware.nvidia-container-toolkit.enable = true;

  # Compose support for multi-container work (podman's own `compose` shim needs it)
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
