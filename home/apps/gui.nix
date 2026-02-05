# GUI Applications
# Graphical desktop applications

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Communication
    slack

    # Browsers
    google-chrome

    # Terminals
    ghostty
  ];
}
