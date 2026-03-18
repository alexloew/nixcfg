# Niri Wayland Compositor
# Scrollable tiling Wayland compositor

{ config, pkgs, inputs, ... }:

{
  # Enable Niri (unstable required: niri-stable v25.08 lacks `include` directive support)
  programs.niri = {
    enable = true;
    package = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;
  };

  # XDG portal for Niri (uses GNOME portal)
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;

  # Swaylock PAM integration for screen lock
  security.pam.services.swaylock = {};
}
