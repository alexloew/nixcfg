# Idle and Display Sleep Configuration
# Display off after 5 minutes of inactivity; suspend after 10 minutes on battery.
#
# A single swayidle instance owns all idle handling. (It used to be split across
# this module and a hand-rolled systemd service in niri.nix, which left two
# swayidle processes racing for the same ext_idle_notify events.)
#
# Locking goes through DMS's lock screen (`dms ipc call lock lock`) so the
# unlock screen matches the DMS greeter shown at boot, instead of bare swaylock.
# swaylock stays as a fallback if the DMS IPC socket isn't reachable, so the
# session never fails to lock. DMS authenticates against /etc/pam.d/login (which
# always exists on NixOS), so no extra PAM service is needed for it.

{ pkgs, inputs, ... }:

let
  # Same niri build as the running compositor (see displays.nix / niri.nix).
  niri = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;

  # DMS CLI (dms-shell) — provides `dms ipc call lock lock`.
  dms = inputs.dms.packages.${pkgs.system}.default;

  # Lock via DMS, falling back to swaylock if DMS's IPC socket isn't reachable
  # (e.g. DMS not yet up). Absolute paths because swayidle's unit pins PATH (see
  # the onBatterySuspend note below).
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    ${dms}/bin/dms ipc call lock lock || ${pkgs.swaylock}/bin/swaylock -f
  '';

  # Suspend only when running on battery. /sys/class/power_supply/A{C,DP}*/online
  # reports 1 on AC, 0 on battery; skip suspend if any adapter is online.
  #
  # swayidle's systemd user unit pins Environment=PATH to only bash-interactive's
  # bin, so external commands (cat, loginctl, ...) are NOT on PATH. Use the bash
  # `read` builtin instead of `cat`, and absolute paths for everything else —
  # otherwise the read fails, the "on AC" check is skipped, and the laptop
  # suspends on AC too.
  onBatterySuspend = pkgs.writeShellScript "idle-suspend-on-battery" ''
    for ac in /sys/class/power_supply/A{C,DP}*/online; do
      [ -e "$ac" ] || continue
      read -r online < "$ac" || continue
      if [ "$online" = "1" ]; then
        exit 0
      fi
    done
    ${pkgs.systemd}/bin/systemctl suspend
  '';
in
{
  services.swayidle = {
    enable = true;

    # events is now an attrset keyed by event name (the list form is deprecated).
    events = {
      before-sleep = "${pkgs.systemd}/bin/loginctl lock-session";
      lock = "${lockScreen}";
    };

    timeouts = [
      {
        timeout = 300;
        command = "${niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${niri}/bin/niri msg action power-on-monitors";
      }
      {
        # Suspend after 10 min idle, but only on battery (the script no-ops on AC).
        timeout = 600;
        command = "${onBatterySuspend}";
      }
    ];
  };
}
