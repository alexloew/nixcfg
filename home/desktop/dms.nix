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
      customThemeFile = "${config.home.homeDirectory}/.config/DankMaterialShell/themes/catppuccin-mocha.json";
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

  # Catppuccin Mocha theme file for DMS
  home.file.".config/DankMaterialShell/themes/catppuccin-mocha.json".text = builtins.toJSON {
    dark = {
      name = "Catppuccin Mocha";
      primary = "#cba6f7";           # mauve
      primaryText = "#1e1e2e";       # base (dark text on mauve)
      primaryContainer = "#7c5ea8";  # darker mauve
      secondary = "#89b4fa";         # blue
      surfaceTint = "#cba6f7";       # mauve
      surface = "#181825";           # mantle
      surfaceText = "#cdd6f4";       # text
      surfaceVariant = "#313244";    # surface0
      surfaceVariantText = "#cdd6f4"; # text
      surfaceContainer = "#181825";  # mantle
      surfaceContainerHigh = "#313244"; # surface0
      surfaceContainerHighest = "#45475a"; # surface1
      background = "#1e1e2e";        # base
      backgroundText = "#cdd6f4";    # text
      outline = "#6c7086";           # overlay0
      error = "#f38ba8";             # red
      warning = "#f9e2af";           # yellow
      info = "#89b4fa";              # blue
      matugen_type = "scheme-tonal-spot";
    };
  };
}
