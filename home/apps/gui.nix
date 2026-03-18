# GUI Applications
# Graphical desktop applications

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Communication
    slack

    # Browsers
    google-chrome
  ];

  # Ghostty terminal with Catppuccin Mocha dark theme
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      background-opacity = 0.88;
      background-blur-radius = 20;
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      font-thicken = true;
    };
  };
}
