# GNOME Desktop Configuration
# Extensions and dconf settings (fallback desktop)

{ pkgs, ... }:

{
  # GNOME Extensions
  home.packages = with pkgs; [
    gnomeExtensions.dash-to-dock
    catppuccin-gtk  # Catppuccin Mocha GTK theme
  ];

  # GTK dark theme — Catppuccin Mocha
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard+default";
      package = pkgs.catppuccin-gtk;
    };
    font = {
      name = "Inter";
      size = 11;
    };
  };

  # dconf settings
  dconf.settings = {
    # System-wide dark mode preference
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "catppuccin-mocha-mauve-standard+default";
    };

    # Shell extensions
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
      ];
    };

    # Dash-to-Dock configuration
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      height-fraction = 0.9;
      dash-max-icon-size = 48;
      click-action = "minimize";
    };
  };
}
