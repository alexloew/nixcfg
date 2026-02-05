# Hyprland Wayland Compositor
# Dynamic tiling Wayland compositor - required for DankMaterialShell

{ config, pkgs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # X11 app compatibility
  };

  # Hyprland-specific XDG portal
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;

  # Session unlock / login support
  security.pam.services.hyprlock = {};
}
