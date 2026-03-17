# Niri Home Configuration
# Window manager settings and keybinds
# DankMaterialShell handles layout, colors, keybinds, bar, launcher, notifications
# See: https://danklinux.com/docs/dankmaterialshell/compositors

{ config, pkgs, lib, ... }:

{
  # Install supporting tools
  home.packages = with pkgs; [
    swaylock      # Screen locker
    grim          # Screenshots
    slurp         # Region selection
    wl-clipboard  # Clipboard support
    swayidle      # Idle management
  ];

  # Ensure DMS include directories exist with empty files
  # Niri will error if included files are missing
  xdg.configFile."niri/dms/.keep" = {
    text = "";
    onChange = ''
      mkdir -p ${config.xdg.configHome}/niri/dms
      for f in colors layout alttab binds; do
        touch ${config.xdg.configHome}/niri/dms/$f.kdl
      done
    '';
  };

  # Niri configuration via niri-flake settings
  programs.niri.settings = {
    # Environment variables for NVIDIA + Wayland
    environment = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # Input configuration
    input = {
      keyboard.xkb.layout = "us";

      touchpad = {
        natural-scroll = true;
        tap = true;
      };

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
    };

    # Output / monitor configuration
    outputs."eDP-1" = {
      scale = 2.0;
    };

    # Decorations - default window rule
    window-rules = [
      {
        opacity = 0.95;
        clip-to-geometry = true;
        geometry-corner-radius = let r = 10.0; in {
          top-left = r;
          top-right = r;
          bottom-left = r;
          bottom-right = r;
        };
      }
      # Force full opacity for browsers and Slack
      {
        matches = [
          { app-id = "^Google-chrome$"; }
          { app-id = "^Slack$"; }
        ];
        opacity = 1.0;
      }
    ];

    # User key bindings (in addition to DMS-managed binds)
    binds = {
      # Application launchers
      "Mod+Return".action.spawn = "ghostty";
      "Mod+B".action.spawn = "firefox";

      # Screenshots (saved to ~/Pictures/Screenshots)
      "Print".action.spawn = [ "sh" "-c" "grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png" ];
      "Mod+Print".action.spawn = [ "sh" "-c" "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png" ];
      # Screenshot to clipboard
      "Mod+Shift+S".action.spawn = [ "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy" ];

      # Window management
      "Mod+Q".action.close-window = [];
      "Mod+Shift+M".action.quit = [];
      "Mod+V".action.toggle-window-floating = [];
      "Mod+F".action.maximize-column = [];
      "Mod+Shift+F".action.fullscreen-window = [];

      # Focus movement (vim-style)
      "Mod+H".action.focus-column-left = [];
      "Mod+L".action.focus-column-right = [];
      "Mod+K".action.focus-window-or-workspace-up = [];
      "Mod+J".action.focus-window-or-workspace-down = [];

      # Arrow key focus movement
      "Mod+Left".action.focus-column-left = [];
      "Mod+Right".action.focus-column-right = [];
      "Mod+Up".action.focus-window-or-workspace-up = [];
      "Mod+Down".action.focus-window-or-workspace-down = [];

      # Move windows (vim-style)
      "Mod+Shift+H".action.move-column-left = [];
      "Mod+Shift+L".action.move-column-right = [];
      "Mod+Shift+K".action.move-window-up-or-to-workspace-up = [];
      "Mod+Shift+J".action.move-window-down-or-to-workspace-down = [];

      # Arrow key move windows
      "Mod+Shift+Left".action.move-column-left = [];
      "Mod+Shift+Right".action.move-column-right = [];
      "Mod+Shift+Up".action.move-window-up-or-to-workspace-up = [];
      "Mod+Shift+Down".action.move-window-down-or-to-workspace-down = [];

      # Column width adjustments
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      # Preset column widths
      "Mod+R".action.switch-preset-column-width = [];

      # Consume / expel windows (merge columns)
      "Mod+BracketLeft".action.consume-or-expel-window-left = [];
      "Mod+BracketRight".action.consume-or-expel-window-right = [];

      # Workspace switching
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+0".action.focus-workspace = 10;

      # Move window to workspace
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;
      "Mod+Shift+0".action.move-column-to-workspace = 10;

      # Scroll through workspaces
      "Mod+WheelScrollDown".action.focus-workspace-down = [];
      "Mod+WheelScrollUp".action.focus-workspace-up = [];

      # Mouse window management
      "Mod+WheelScrollRight".action.focus-column-right = [];
      "Mod+WheelScrollLeft".action.focus-column-left = [];
    };

    # Cursor settings
    cursor = {
      theme = "Adwaita";
      size = 24;
    };

    # Screenshot path
    screenshot-path = "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png";
  };
}
