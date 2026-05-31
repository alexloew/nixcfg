# DankMaterialShell greeter (greetd) — replaces GDM as the login manager.
#
# Why: GDM-50's Wayland greeter is broken on the 05-23 tree (issue #111).
# `gdm-wayland-session` does a bare `execvp("gnome-session")` against a
# PAM-reset PATH that lacks gnome-session, so it exits 70 six times and the
# machine never reaches a desktop. Rather than patch GDM, we drop it and log
# in through the stack we already run: niri + DankMaterialShell.
#
# This uses the in-tree nixpkgs module `services.displayManager.dms-greeter`
# (NOT the dms flake's `nixosModules.greeter`), which is lighter to build
# (nixpkgs quickshell is cached; the flake pins quickshell to an unreleased
# git rev that must be built from source) and self-contained: it enables
# greetd, creates the `dms-greeter` system user + group, wires
# security.pam.services.dms-greeter, and enables hardware.graphics + libinput.
# The greeter runs inside niri (`programs.niri.enable = true`, system/desktop/
# niri.nix), reusing the same niri-flake package as the logged-in session.

{ config, pkgs, ... }:

{
  services.displayManager = {
    # Pre-select the niri (DMS) session in the greeter; GNOME stays available
    # as a fallback the user can pick from the session list.
    defaultSession = "niri";

    dms-greeter = {
      enable = true;

      # Run the greeter inside niri — same compositor as the desktop, far
      # simpler KMS path than mutter-50, and our daily driver.
      compositor.name = "niri";

      # Carry the user's DMS theme/wallpaper/colors into the greeter by
      # copying the standard XDG config files (settings.json, session.json,
      # dms-colors.json) into /var/lib/dms-greeter at greetd preStart.
      configHome = "/home/alexloewenthal";

      # Persist greeter + compositor output to a file for first-boot triage.
      # Safe to drop once login is confirmed stable across a few boots.
      logs = {
        save = true;
        path = "/var/log/dms-greeter.log";
      };
    };
  };
}
