# Hardware Services Configuration
# Audio, printing, and other hardware-related services

{ ... }:

{
  # Audio - PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Printing - CUPS
  services.printing.enable = true;

  # Lid-close behavior:
  # - Docked (external displays connected): ignore. Niri disconnects eDP-1 and
  #   the topology watcher moves Slack beside Chrome on the external outputs.
  # - Undocked (battery or AC, no external displays): suspend, so the laptop
  #   does not burn its battery sitting in a bag with the lid closed.
  # logind lid options moved under services.logind.settings.Login in nixpkgs.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Niri handles kernel lid events and panel state directly. Do not bridge lid
  # events through acpid into the user manager: the lid can open while
  # user.slice is still frozen, causing the `output eDP-1 on` dispatch to fail
  # and leaving the compositor with no active output after resume.

  # NOTE (issue #111): there is deliberately no DRM udev rule restarting
  # configure-displays. The old rule formed a modeset/uevent restart loop during
  # boot. Niri now applies output modes and positions natively on connection.

  # Do not restart graphical user services unconditionally on resume. DMS
  # restores its own Wayland surfaces, while Niri topology events start display
  # reconciliation once an output is active.
}
