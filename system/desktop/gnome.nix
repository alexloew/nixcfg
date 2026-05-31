# GNOME Desktop Environment
# X11/Wayland GNOME configuration
#
# Login is handled by the DankMaterialShell greeter on greetd (see
# ./dms-greeter.nix), NOT GDM. GDM-50's Wayland greeter is broken on this
# tree (issue #111: gdm-wayland-session can't exec `gnome-session` — ENOENT,
# the binary is absent from the PAM-reset greeter PATH — so it exits 70 six
# times and never presents a desktop). GNOME stays installed as a *fallback
# session* the greeter can launch; it is just no longer the display manager.

{ config, pkgs, ... }:

{
  # Enable X11 windowing system (also drives the GNOME desktopManager wiring)
  services.xserver.enable = true;

  # GDM is DISABLED — its GNOME-50 Wayland greeter never starts here (#111).
  # The DMS/greetd greeter in ./dms-greeter.nix replaces it.
  services.displayManager.gdm.enable = false;

  # GNOME Desktop — kept as a selectable fallback session in the greeter.
  services.xserver.desktopManager.gnome.enable = true;
}
