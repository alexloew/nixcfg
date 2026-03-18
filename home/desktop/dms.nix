# DankMaterialShell Configuration
# Desktop shell for Wayland compositors (Niri)
# https://danklinux.com/docs/dankmaterialshell/nixos-flake

{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = true;
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;

    # Catppuccin Mocha custom theme
    settings = {
      currentThemeName = "custom";
      customThemeFile = "${config.home.homeDirectory}/.config/DankMaterialShell/themes/pure-dark.json";

      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;
          leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
          centerWidgets = [ "music" "clock" "weather" ];
          rightWidgets = [ "systemTray" "clipboard" "cpuUsage" "memUsage" "notificationButton" "battery" "controlCenterButton" ];
          spacing = 4;
          innerPadding = 4;
          bottomGap = 0;
          transparency = 0.60;
          widgetTransparency = 0.75;
          squareCorners = false;
          noBackground = false;
          gothCornersEnabled = false;
          gothCornerRadiusOverride = false;
          gothCornerRadiusValue = 12;
          borderEnabled = false;
          borderColor = "surfaceText";
          borderOpacity = 1;
          borderThickness = 1;
          fontScale = 1;
          autoHide = false;
          autoHideDelay = 250;
          openOnOverview = false;
          visible = true;
          popupGapsAuto = true;
          popupGapsManual = 4;
          maximizeWidgetIcons = false;
          maximizeWidgetText = false;
          removeWidgetPadding = false;
          clickThrough = false;
        }
      ];
    };

    # Niri compositor integration
    # DMS manages keybinds, layout, colors, and alt-tab via include files
    niri = {
      enableKeybinds = true;
      # Don't use enableSpawn since systemd.enable = true
      includes = {
        enable = true;
        filesToInclude = [ "alttab" "binds" "colors" "layout" ];
      };
    };
  };

  # Pure dark theme file for DMS
  home.file.".config/DankMaterialShell/themes/pure-dark.json".text = builtins.toJSON {
    dark = {
      name = "Pure Dark";
      primary = "#d4d4d4";
      primaryText = "#0d0d0d";
      primaryContainer = "#2a2a2a";
      secondary = "#8a8a8a";
      surfaceTint = "#d4d4d4";
      surface = "#161616";
      surfaceText = "#e0e0e0";
      surfaceVariant = "#212121";
      surfaceVariantText = "#e0e0e0";
      surfaceContainer = "#161616";
      surfaceContainerHigh = "#212121";
      surfaceContainerHighest = "#2a2a2a";
      background = "#0d0d0d";
      backgroundText = "#e0e0e0";
      outline = "#3a3a3a";
      error = "#cf6679";
      warning = "#c9a84c";
      info = "#6a9fb5";
      matugen_type = "scheme-neutral";
    };
  };
}
