# distrobox
# Mutable dev containers that share $HOME, for tooling that expects a
# conventional FHS distro (apt/dpkg, prebuilt binaries, vendor installers).
# Backend is rootless podman, enabled in system/containers.nix.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    distrobox
  ];

  # Baseline defaults. Anything here can be overridden per-invocation with
  # `distrobox create` flags, or per-box in assemble.ini below.
  xdg.configFile."distrobox/distrobox.conf".text = ''
    container_manager="podman"

    # Toolbx images ship the sudo/locale/entrypoint bits distrobox expects,
    # so first-run setup is much shorter than with a bare ubuntu:26.04.
    container_image_default="quay.io/toolbx/ubuntu-toolbox:26.04"
    container_name_default="ubuntu"

    # $HOME is shared with the host by default: dotfiles, ssh agent socket and
    # project checkouts are all visible inside the box. Nix-built binaries on
    # $PATH generally still work because /nix is bind-mounted read-only.
    container_additional_volumes="/nix:/nix:ro"

    # Installed on create, on top of whatever the image provides.
    container_additional_packages="build-essential curl git less"

    # Boxes are graphical, not headless: distrobox already shares the Wayland
    # and X11 sockets, dbus, PulseAudio/PipeWire and /dev/dri, so GUI apps run
    # against the host session. This exports their .desktop entries to the host
    # launcher; `distrobox-export --app <name>` exports one after the fact.
    container_generate_entry=1

    # Don't hit the registry on every enter; pull explicitly when refreshing.
    container_always_pull=0

    # Start in $HOME rather than the host cwd, so a box entered from a
    # Nix-store path doesn't land somewhere read-only.
    skip_workdir=1
  '';

  # Declarative box definitions: `distrobox assemble create --all` creates any
  # that are missing. The containers themselves stay mutable — this file only
  # describes how they are (re)created.
  #
  # nvidia=true injects the host driver via the container toolkit. The display
  # is driven by the Intel iGPU in PRIME offload mode (system/nvidia.nix), so
  # GUI apps work without it; it's for CUDA / explicit dGPU offload.
  xdg.configFile."distrobox/assemble.ini".text = ''
    [ubuntu]
    image=quay.io/toolbx/ubuntu-toolbox:26.04
    additional_packages="build-essential curl git less"
    start_now=false
    nvidia=true

    [fedora]
    image=registry.fedoraproject.org/fedora-toolbox:45
    additional_packages="@development-tools curl git less"
    start_now=false
    nvidia=true

    [arch]
    image=quay.io/toolbx/arch-toolbox:latest
    additional_packages="base-devel git less curl"
    start_now=false
    nvidia=true
  '';
}
