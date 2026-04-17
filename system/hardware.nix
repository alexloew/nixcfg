# Hardware Services Configuration
# Audio, printing, and other hardware-related services

{ config, pkgs, ... }:

let
  username = "alexloewenthal";
in
{
  # Audio - PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing - CUPS
  services.printing.enable = true;

  # Lid-close: disable eDP-1, keep DP-1 as primary when external displays are connected
  # logind must not act on lid events — the systemd user service handles output toggling
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";

  # Fire the user-level lid-handler service when the lid state changes
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="button", KERNEL=="button/lid", \
      RUN+="${pkgs.systemd}/bin/systemctl --no-block --user --machine=${username}@.host start lid-handler.service"

    # Reconfigure displays on DRM hotplug (display hub connect/disconnect)
    ACTION=="change", SUBSYSTEM=="drm", \
      RUN+="${pkgs.systemd}/bin/systemctl --no-block --user --machine=${username}@.host restart configure-displays.service"
  '';

  powerManagement.resumeCommands = ''
    sleep 3
    ${pkgs.systemd}/bin/systemctl --user -M ${username}@ restart dms.service || true
    ${pkgs.systemd}/bin/systemctl --user -M ${username}@ restart configure-displays.service || true
  '';
}
