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

  # Lid-close behavior:
  # - Docked (external displays connected): ignore — lid-handler turns off eDP-1
  #   so the docked workflow keeps running on external monitors.
  # - Undocked (battery or AC, no external displays): suspend, so the laptop
  #   doesn't burn its battery sitting in a bag with the lid closed.
  services.logind.lidSwitch = "suspend";
  services.logind.lidSwitchExternalPower = "suspend";
  services.logind.lidSwitchDocked = "ignore";

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
