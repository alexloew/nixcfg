# DankMaterialShell Configuration
# Desktop shell for Wayland compositors
# https://danklinux.com/docs/dankmaterialshell/nixos-flake

{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    # dgop not available in nixpkgs stable 25.11
    enableSystemMonitoring = false;
  };
}
