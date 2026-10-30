# Containers
# Rootless Podman, used as the backend for distrobox (see home/dev/distrobox.nix)

{ config, lib, pkgs, ... }:

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

  # A switch can update NVIDIA userspace while the previous kernel module is
  # still loaded. Avoid restarting the generator just because its unit changed.
  # The toolkit's udev rule can still explicitly restart it during activation,
  # so skip that known mismatch without failing the unit or deleting an existing
  # CDI spec. GPU containers require matching drivers; reboot into the new
  # generation to regenerate the spec. Other generator failures remain fatal.
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    restartIfChanged = false;
    serviceConfig = {
      RuntimeDirectoryPreserve = "yes";
      ExecCondition = pkgs.writeShellScript "nvidia-cdi-driver-check" ''
        if [ -r /sys/module/nvidia/version ]; then
          read -r loaded_version < /sys/module/nvidia/version
          expected_version=${lib.escapeShellArg config.hardware.nvidia.package.version}
          if [ "$loaded_version" != "$expected_version" ]; then
            echo "Skipping NVIDIA CDI generation: loaded module $loaded_version != configured driver $expected_version; reboot into the new generation to enable GPU containers." >&2
            exit 1
          fi
        fi
        exit 0
      '';
    };
  };

  # Compose support for multi-container work (podman's own `compose` shim needs it)
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
