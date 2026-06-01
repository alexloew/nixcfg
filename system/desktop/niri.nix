# Niri Wayland Compositor
# Scrollable tiling Wayland compositor

{ config, pkgs, inputs, ... }:

{
  # Niri compositor — niri-unstable.
  #
  # DMS needs the `include` directive, which niri-flake's niri-stable still
  # lacks (it pins v25.08, pre-`include`), so stable isn't an option here.
  # Instead, niri-flake is pinned to a fixed rev in flake.nix so this
  # niri-unstable build can't drift on `nix flake update` and re-break the
  # DMS-generated configs the way the original unpin did (#111 → #128/#130).
  programs.niri = {
    enable = true;
    package = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;
  };

  # XDG portal for Niri (uses GNOME portal)
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;

  # Swaylock PAM integration for screen lock
  security.pam.services.swaylock = {};
}
