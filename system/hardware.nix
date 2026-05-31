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

    # NOTE (issue #111): there is deliberately NO `ACTION=change, SUBSYSTEM=drm`
    # rule restarting configure-displays. That rule was the boot livelock: at boot
    # the DRM nodes re-probe and re-enumerate racily, firing change uevents that
    # restarted configure-displays, whose `niri msg output … mode …` modeset emitted
    # a fresh change uevent (carrying HOTPLUG=1, so the gate could not filter it) →
    # infinite restart storm → hang. The #115 HOTPLUG gate and #116 idempotency
    # guard both failed to hold during the boot enumeration race. Modes/positions
    # are now applied natively by niri's own output config (home/desktop/niri.nix)
    # on output connect — including real hotplug — so this rule is unnecessary.
  '';

  powerManagement.resumeCommands = ''
    sleep 3
    ${pkgs.systemd}/bin/systemctl --user -M ${username}@ restart dms.service || true
    ${pkgs.systemd}/bin/systemctl --user -M ${username}@ restart configure-displays.service || true
  '';
}
