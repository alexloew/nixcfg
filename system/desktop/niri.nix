# Niri Wayland Compositor
# Scrollable tiling Wayland compositor

{ config, pkgs, niriPackage, ... }:

{
  # Use the shared upstream package for the user session and DMS greeter.
  programs.niri = {
    enable = true;
    package = niriPackage;
  };

  # XDG portal for Niri (uses GNOME portal)
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;

  # Swaylock PAM integration for screen lock
  security.pam.services.swaylock = {};
}
