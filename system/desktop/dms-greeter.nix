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

let
  greeterLog = "/var/log/dms-greeter.log";
in
{
  # The greeter's `dms-greeter-start` script (run as the unprivileged
  # `dms-greeter` user) redirects its output with `> ${greeterLog}`. The
  # nixpkgs module never creates that file, and /var/log is root-owned 0755,
  # so the redirect dies with "Permission denied". Pre-create the file owned by
  # the greeter user so the shell can open (and truncate) it on each start.
  systemd.tmpfiles.settings."10-dms-greeter-log".${greeterLog}.f = {
    user = "dms-greeter";
    group = "dms-greeter";
    mode = "0644";
  };

  services.displayManager = {
    # Pre-select the niri (DMS) session in the greeter; GNOME stays available
    # as a fallback the user can pick from the session list.
    defaultSession = "niri";

    dms-greeter = {
      enable = true;

      # Run the greeter inside niri — same compositor as the desktop, far
      # simpler KMS path than mutter-50, and our daily driver.
      compositor.name = "niri";

      # Replace the dms-shell greeter's built-in niri config.
      #
      # The bundled default (dms-shell 1.4.6) emits `debug {
      # keep-max-bpc-unchanged }` and `layout { background-color }`, options our
      # niri rejected (originally surfaced on niri-unstable 2026-05-29). niri then
      # rejected the greeter config, fell back to its built-in defaults, and never
      # spawned the
      # DMS login UI — so the login screen is a bare gray niri with a "failed to
      # parse the config file" banner. (The niri_overrides hook only *appends*
      # via include, so it can't remove the bad lines; customConfig *replaces*
      # the default, and the greeter wrapper still auto-appends the login-UI
      # spawn-at-startup.) Keep only options valid on current niri;
      # DMS_RUN_GREETER signals greeter mode to quickshell.
      compositor.customConfig = ''
        hotkey-overlay {
            skip-at-startup
        }

        environment {
            DMS_RUN_GREETER "1"
        }

        gestures {
            hot-corners {
                off
            }
        }
      '';

      # Carry the user's DMS theme/wallpaper/colors into the greeter by
      # copying the standard XDG config files (settings.json, session.json,
      # dms-colors.json) into /var/lib/dms-greeter at greetd preStart.
      configHome = "/home/alexloewenthal";

      # Persist greeter + compositor output to a file for first-boot triage.
      # Safe to drop once login is confirmed stable across a few boots.
      logs = {
        save = true;
        path = greeterLog;
      };
    };
  };
}
