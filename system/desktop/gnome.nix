# GNOME Desktop Environment
# X11/Wayland GNOME configuration

{ config, pkgs, ... }:

{
  # Enable X11 windowing system
  services.xserver.enable = true;

  # GDM Display Manager
  services.displayManager.gdm.enable = true;

  # GNOME Desktop
  services.xserver.desktopManager.gnome.enable = true;

  # DIAGNOSTIC (issue #111) — capture WHY the GDM Wayland greeter bails on the
  # 05-23 tree. After #119 killed the DRM-uevent storm, gen 207 reaches
  # graphical.target cleanly but `gdm-wayland-session` exits nonzero 6× with NO
  # log line, no coredump, no kernel trap, and GDM never falls back to X11 — so
  # the default-level journal can't explain the failure. This turns the greeter
  # verbose so the next failed boot self-documents (read via `journalctl -b -1`).
  # REVERT once the root cause is identified.
  services.displayManager.gdm.debug = true;

  # The greeter compositor (gnome-shell/mutter) is spawned as a child of
  # display-manager.service, so it inherits this environment. MUTTER_DEBUG
  # surfaces the KMS/GPU-selection path (the prime suspect: mutter-50 tripping
  # on the crtc-less NVIDIA offload node or simpledrm card0); G_MESSAGES_DEBUG
  # unmutes GLib/GObject warnings the greeter would otherwise swallow.
  systemd.services.display-manager.environment = {
    G_MESSAGES_DEBUG = "all";
    MUTTER_DEBUG = "backend,kms,render";
    MUTTER_DEBUG_DUMP_OPENGL_INFO = "1";
  };
}
