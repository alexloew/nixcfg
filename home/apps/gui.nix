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
      font-size = 13;
    };
  };
}
