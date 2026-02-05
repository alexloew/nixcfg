# GNOME Desktop Configuration
# Extensions and dconf settings (fallback desktop)

{ pkgs, ... }:

{
  # GNOME Extensions
  home.packages = with pkgs; [
    gnomeExtensions.dash-to-dock
  ];

  # dconf settings
  dconf.settings = {
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
