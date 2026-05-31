# Desktop Environments - Aggregator
# Display servers and desktop environment configurations
# Login: DankMaterialShell greeter on greetd (./dms-greeter.nix) — GDM disabled
# (its GNOME-50 Wayland greeter is broken here, issue #111). Niri is the
# compositor for both the greeter and the DMS desktop session; GNOME remains a
# selectable fallback session.

{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./gnome.nix
    ./niri.nix
    ./dms-greeter.nix
  ];
}
