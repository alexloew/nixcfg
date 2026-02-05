# Font Configuration
# Fonts for desktop environments and terminals

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Nerd Fonts (patched with icons)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack

    # System fonts
    inter
    roboto

    # Icon fonts
    font-awesome
  ];

  # Font configuration
  fonts.fontconfig.enable = true;
}
