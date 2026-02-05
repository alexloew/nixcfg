# Hardware Services Configuration
# Audio, printing, and other hardware-related services

{ config, pkgs, ... }:

{
  # Audio - PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;  # Uncomment for JACK applications
  };

  # Printing - CUPS
  services.printing.enable = true;
}
