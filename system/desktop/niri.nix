# Niri Wayland Compositor
# Scrollable tiling Wayland compositor

{ config, pkgs, ... }:

{
  # Enable Niri
  programs.niri.enable = true;

  # XDG portal for Niri (uses GNOME portal)
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;

  # Swaylock PAM integration for screen lock
  security.pam.services.swaylock = {};
}
