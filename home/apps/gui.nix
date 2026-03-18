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
      # Catppuccin Mocha colors (manual, theme file not bundled)
      background = "#1e1e2e";
      foreground = "#cdd6f4";
      cursor-color = "#f5e0dc";
      selection-background = "#313244";
      selection-foreground = "#cdd6f4";

      # 16-color palette (Catppuccin Mocha)
      palette = [
        "0=#45475a"  "1=#f38ba8"  "2=#a6e3a1"  "3=#f9e2af"
        "4=#89b4fa"  "5=#f5c2e7"  "6=#94e2d5"  "7=#bac2de"
        "8=#585b70"  "9=#f38ba8"  "10=#a6e3a1" "11=#f9e2af"
        "12=#89b4fa" "13=#f5c2e7" "14=#94e2d5" "15=#a6adc8"
      ];

      background-opacity = 0.88;
      background-blur-radius = 20;
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      font-thicken = true;
    };
  };
}
