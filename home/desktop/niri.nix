# Niri Home Configuration
# Window manager settings and keybinds
# DankMaterialShell handles layout, colors, keybinds, bar, launcher, notifications
# See: https://danklinux.com/docs/dankmaterialshell/compositors

{ config, pkgs, lib, ... }:

{
  # Install supporting tools
  home.packages = with pkgs; [
    swaylock      # Screen locker
    swaybg        # Wallpaper setter (per-output)
    grim          # Screenshots
    slurp         # Region selection
    wl-clipboard  # Clipboard support
    swayidle      # Idle management
  ];

  # Niri configuration via niri-flake settings
  programs.niri.settings = {
    # Environment variables for NVIDIA + Wayland
    environment = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # Remove client-side decorations (cleaner look, matches Wynn-Dots style)
    prefer-no-csd = true;

    # Input configuration
    input = {
      keyboard.xkb.layout = "us";

      touchpad = {
        natural-scroll = true;
        tap = true;
      };
      
      mouse = {
          natural-scroll = true;
        }; 

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
    };

    # Output configuration — niri requires connector names (not EDID strings).
    # Kanshi overrides modes/positions via EDID after startup.
    # Current hardware: DP-1=AW2725DF (27-inch), DP-2=AW3423DWF (ultrawide)
    outputs = {
      "eDP-1" = { scale = 2.0; };
      "DP-1" = {
        mode = { width = 2560; height = 1440; refresh = 143.969; };
        position = { x = 0; y = 0; };
        scale = 1.0;
      };
      "DP-2" = {
        mode = { width = 3440; height = 1440; refresh = 99.982; };
        position = { x = 2560; y = 0; };
        scale = 1.0;
      };
    };


    # Layout: DMS manages gaps, borders, corner-radius, and colors
    # via included KDL files (layout.kdl, colors.kdl)
    # Configure those in DMS Settings → Compositor
    layout = {
      # Focus ring: subtle dark border (DMS may override via colors.kdl —
      # if it does, change `primary` in dms.nix to a darker value)
      focus-ring = {
        width = 2;
        active.color = "#4a4a4a";
        inactive.color = "#252525";
      };

      # Shadow (not managed by DMS)
      shadow = {
        enable = true;
        softness = 12;
        spread = 3;
        offset = { x = 0; y = 2; };
        color = "#0d0d0dcc";
        inactive-color = "#0d0d0d88";
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
      workspace-switch.kind.spring = {
        damping-ratio = 0.8;
        stiffness = 1000;
        epsilon = 0.0001;
      };
      horizontal-view-movement.kind.spring = {
        damping-ratio = 0.8;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-open.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-cubic";
      };
      window-close.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-cubic";
      };
      window-movement.kind.spring = {
        damping-ratio = 0.8;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-resize.kind.spring = {
        damping-ratio = 0.8;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };

    # Layer rules: transparency for DMS bar and overlays
    # Opacity 1.0 here — DMS's own `transparency = 0.5` controls bar bg alpha;
    # adding compositor opacity on top would double-reduce it.
    layer-rules = [
      {
        matches = [{ namespace = "^dms:bar$"; }];
        opacity = 1.0;
      }
      {
        matches = [{ namespace = "^quickshell$"; }];
        opacity = 1.0;
      }
    ];

    # Window rules: opacity + per-app overrides
    # DMS manages corner-radius and borders via layout.kdl
    window-rules = [
      # Base rule: default opacity for all windows
      {
        clip-to-geometry = true;
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
          { app-id = "^google-chrome$"; }
          { app-id = "^firefox$"; }
          { app-id = "^Slack$"; }
          { app-id = "^mpv$"; }
          { app-id = "^vlc$"; }
        ];
        opacity = 1.0;
      }
      # Chrome + Ghostty: open maximized; configure-displays focuses the correct
      # output before spawning so they land on the ultrawide
      {
        matches = [
          { app-id = "^google-chrome$"; }
          { app-id = "^com\\.mitchellh\\.ghostty$"; }
        ];
        open-maximized = true;
      }
      # Slack: open maximized on 27-inch (configure-displays focuses it before spawn)
      {
        matches = [{ app-id = "^Slack$"; }];
        open-maximized = true;
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

    # Apps are launched by configure-displays.service (displays.nix) so it can
    # focus the correct output before spawning, bypassing unstable connector names
    spawn-at-startup = [];
  };

  # Lid-close handler: toggle eDP-1 off/on via niri msg
  # Triggered by the system udev rule on button/lid change events
  systemd.user.services.lid-handler = {
    Unit.Description = "Toggle eDP-1 output on lid close/open";
    Service = let
      script = pkgs.writeShellScript "lid-handler" ''
        state=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null || \
                cat /proc/acpi/button/lid/LID/state 2>/dev/null)
        if echo "$state" | grep -q "closed"; then
          ${pkgs.niri}/bin/niri msg output eDP-1 off
        else
          ${pkgs.niri}/bin/niri msg output eDP-1 on
        fi
      '';
    in {
      Type = "oneshot";
      ExecStart = "${script}";
    };
  };

  # Wallpaper — KCD2 shepherd scene
  home.file.".local/share/wallpapers/kcd2-shepherd.jpg".source = ./wallpapers/kcd2-shepherd.jpg;
  home.file.".local/share/wallpapers/kcd2-shepherd-wallpaper-ultrawide.jpg".source = ./wallpapers/kcd2-shepherd-wallpaper-ultrawide.jpg;
}
