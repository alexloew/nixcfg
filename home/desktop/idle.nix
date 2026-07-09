# Idle and Display Sleep Configuration
# Display off after 5 minutes of inactivity; suspend after 10 minutes on battery.
#
# A single swayidle instance owns all idle handling. (It used to be split across
# this module and a hand-rolled systemd service in niri.nix, which left two
# swayidle processes racing for the same ext_idle_notify events.)

{ pkgs, inputs, ... }:

let
  # Same niri build as the running compositor (see displays.nix / niri.nix).
  niri = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;

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
      lock = "${pkgs.swaylock}/bin/swaylock -f";
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
