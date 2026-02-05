# Home Configuration - Entry Point
# This is the main branch for all home-manager configuration.
# Sub-branches handle specific concerns: shell, editors, apps, desktop.

{ config, pkgs, inputs, ... }:

{
  home.username = "alexloewenthal";
  home.homeDirectory = "/home/alexloewenthal";
  home.stateVersion = "25.11";

  imports = [
    ./shell
    ./editors
    ./apps
    ./desktop
  ];

  programs.home-manager.enable = true;
}
