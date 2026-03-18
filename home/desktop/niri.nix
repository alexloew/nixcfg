# Niri Home Configuration
# Window manager settings and keybinds
# DankMaterialShell handles layout, colors, keybinds, bar, launcher, notifications
# See: https://danklinux.com/docs/dankmaterialshell/compositors

{ config, pkgs, lib, ... }:

let
  # Catppuccin Mocha palette
  catppuccin = {
    rosewater = "#f5e0dc";
    flamingo  = "#f2cdcd";
    pink      = "#f5c2e7";
    mauve     = "#cba6f7";
    red       = "#f38ba8";
    maroon    = "#eba0ac";
    peach     = "#fab387";
    yellow    = "#f9e2af";
    green     = "#a6e3a1";
    teal      = "#94e2d5";
    sky       = "#89dceb";
    sapphire  = "#74c7ec";
    blue      = "#89b4fa";
    lavender  = "#b4befe";
    text      = "#cdd6f4";
    subtext1  = "#bac2de";
    overlay0  = "#6c7086";
    surface0  = "#313244";
    base      = "#1e1e2e";
    mantle    = "#181825";
    crust     = "#11111b";
  };
in
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

    # Layout: borders, gaps, shadow
    layout = {
      gaps = 8;

      border = {
        enable = true;
        width = 2;
        active.gradient = {
          from = catppuccin.blue;
          to = catppuccin.mauve;
          angle = 45;
        };
        inactive.color = "${catppuccin.surface0}aa";
      };

      focus-ring.enable = false;

      shadow = {
        enable = true;
        softness = 12;
        spread = 3;
        offset = { x = 0; y = 2; };
        color = "#1a1a2ecc";
        inactive-color = "#1a1a2e88";
      };

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
        { proportion = 1.0; }
      ];

      default-column-width.proportion = 1.0 / 2.0;
    };

    # Animations
    animations = {
      workspace-switch.spring = {
        damping-ratio = 0.8;
        stiffness = 1000;
        epsilon = 0.0001;
      };
      horizontal-view-movement.spring = {
        damping-ratio = 0.8;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-open.easing = {
        duration-ms = 200;
        curve = "ease-out-cubic";
      };
      window-close.easing = {
        duration-ms = 150;
        curve = "ease-out-cubic";
      };
      window-movement.spring = {
        damping-ratio = 0.8;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-resize.spring = {
        damping-ratio = 0.8;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };

    # Window rules: default styling + per-app overrides
    window-rules = [
      # Base rule: rounded corners for all windows
      {
        clip-to-geometry = true;
        geometry-corner-radius = let r = 10.0; in {
          top-left = r;
          top-right = r;
          bottom-left = r;
          bottom-right = r;
        };
        opacity = 0.95;
      }
      # Inactive windows: more transparent
      {
        matches = [{ is-active = false; }];
        opacity = 0.85;
      }
      # Terminals: extra transparency for that dark-mode-through-glass look
      {
        matches = [
          { app-id = "^com\\.mitchellh\\.ghostty$"; }
          { app-id = "^Alacritty$"; }
          { app-id = "^kitty$"; }
          { app-id = "^foot$"; }
        ];
        opacity = 0.88;
      }
      # Browsers and media: always fully opaque
      {
        matches = [
          { app-id = "^Google-chrome$"; }
          { app-id = "^firefox$"; }
          { app-id = "^Slack$"; }
          { app-id = "^mpv$"; }
          { app-id = "^vlc$"; }
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
      "Mod+Shift+V".action.toggle-window-floating = [];
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
