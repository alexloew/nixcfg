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

      use24HourClock = false;
      useFahrenheit = true;
      windSpeedUnit = "mph";

      # Compositor blur on DMS surfaces (bar, popouts, modals, notifications).
      # Niri 26.04+ implements ext-background-effect-v1; DMS asks the compositor
      # to blur its surfaces at runtime when this is true.
      blurEnabled = true;

      # Idle / power management — DMS's native idle daemon owns this now,
      # replacing the old swayidle service (home/desktop/idle.nix). Timeouts are
      # in seconds; 0 disables that action. Split AC vs battery:
      #   - Displays off after 5 min on both AC and battery.
      #   - Suspend after 10 min on battery only; never auto-suspend on AC.
      #   - Lock before suspending, so waking requires the password.
      # loginctlLockIntegration makes `loginctl lock-session` (and thus the
      # logind lock signal on suspend) show the DMS lock screen.
      acMonitorTimeout = 300;       # displays off @ 5 min on AC
      batteryMonitorTimeout = 300;  # displays off @ 5 min on battery
      acSuspendTimeout = 0;         # never auto-suspend on AC
      batterySuspendTimeout = 600;  # suspend @ 10 min on battery
      lockBeforeSuspend = true;
      loginctlLockIntegration = true;

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
          rightWidgets = [ "systemTray" "clipboard" "vpn" "cpuUsage" "memUsage" "notificationButton" "battery" "controlCenterButton" ];
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
    # DMS manages layout, colors, and alt-tab via include files. Output
    # modes/positions are owned solely by niri.nix (hand-tuned per connector);
    # "outputs" is deliberately NOT included here to avoid two output authorities
    # writing the same connector blocks.
    #
    # Keybinds come from ONE source only: the niri-flake settings, which merge
    # our binds (niri.nix) with DMS's IPC binds (enableKeybinds — Mod+Space,
    # Mod+V, etc.). We deliberately do NOT include "binds" here: that pulls in
    # DMS's runtime-generated dms/binds.kdl, whose default binds collide with
    # the binds already in config.kdl. niri >= 26.05 rejects duplicate binds to
    # the same key with a hard "failed to parse the config file" error (older
    # niri silently kept the first bind). Including both sources is what DMS's
    # own module warns against ("not recommended to use both enableKeybinds and
    # includes.enable at the same time").
    niri = {
      enableKeybinds = true;
      # Don't use enableSpawn since systemd.enable = true
      includes = {
        enable = true;
        filesToInclude = [ "alttab" "layout" ];
      };
    };
  };

  # Auto-restart DMS if it crashes (e.g. on wake from sleep).
  # home-manager maps this to the unit's [Service] section, so the key must be
  # `Service` — `serviceConfig` produced a bogus [serviceConfig] section that
  # systemd ignored ("Unknown section 'serviceConfig'"), so the override never
  # applied.
  systemd.user.services.dms = {
    Service = {
      Restart = "on-failure";
      RestartSec = "3s";
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
