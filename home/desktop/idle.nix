# Idle and Display Sleep Configuration
# Display off after 5 minutes of inactivity; suspend after 10 minutes on battery.
#
# A single swayidle instance owns all idle handling. (It used to be split across
# this module and a hand-rolled systemd service in niri.nix, which left two
# swayidle processes racing for the same ext_idle_notify events.)

{ pkgs, ... }:

let
  # Suspend only when running on battery. /sys/class/power_supply/A{C,DP}*/online
  # reports 1 on AC, 0 on battery; skip suspend if any adapter is online.
  onBatterySuspend = pkgs.writeShellScript "idle-suspend-on-battery" ''
    for ac in /sys/class/power_supply/A{C,DP}*/online; do
      [ -e "$ac" ] || continue
      if [ "$(cat "$ac")" = "1" ]; then
        exit 0
      fi
    done
    ${pkgs.systemd}/bin/systemctl suspend
  '';
in
{
  services.swayidle = {
    enable = true;

    events = [
      { event = "before-sleep"; command = "loginctl lock-session"; }
      { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    ];

    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
      {
        # Suspend after 10 min idle, but only on battery (the script no-ops on AC).
        timeout = 600;
        command = "${onBatterySuspend}";
      }
    ];
  };
}
