# Idle and Display Sleep Configuration
# Display off after 5 minutes of inactivity

{ pkgs, ... }:

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
    ];
  };
}
