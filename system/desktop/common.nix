# Common Desktop Configuration
# Shared settings for all desktop environments

{ config, pkgs, ... }:

{
  # Keyboard layout (applies to X11 and Wayland)
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Firefox (system-level)
  programs.firefox.enable = true;

  # XDG Portal (required for screen sharing, file dialogs in Wayland)
  xdg.portal.enable = true;
}
