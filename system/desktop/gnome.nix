# GNOME Desktop Environment
# X11/Wayland GNOME configuration

{ config, pkgs, ... }:

{
  # Enable X11 windowing system
  services.xserver.enable = true;

  # GDM Display Manager
  services.xserver.displayManager.gdm.enable = true;

  # GNOME Desktop
  services.xserver.desktopManager.gnome.enable = true;
}
