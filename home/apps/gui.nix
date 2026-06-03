# GUI Applications
# Graphical desktop applications

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Communication
    slack

    # Music
    spotify

    # Browsers
    google-chrome

    # Notes
    obsidian
  ];

  # Ghostty terminal with Catppuccin Mocha dark theme
  programs.ghostty = {
    enable = true;
    settings = {
      # Pure dark colors
      background = "#0d0d0d";
      foreground = "#e0e0e0";
      cursor-color = "#d4d4d4";
      selection-background = "#2a2a2a";
      selection-foreground = "#e0e0e0";

      # 16-color palette (neutral dark)
      palette = [
        "0=#1a1a1a"  "1=#cf6679"  "2=#6aab75"  "3=#c9a84c"
        "4=#6a9fb5"  "5=#9a7fbf"  "6=#5a9fa8"  "7=#c0c0c0"
        "8=#3a3a3a"  "9=#cf6679"  "10=#6aab75" "11=#c9a84c"
        "12=#6a9fb5" "13=#9a7fbf" "14=#5a9fa8" "15=#e0e0e0"
      ];

      background-opacity = 1.0;
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      font-thicken = true;
    };
  };
}
