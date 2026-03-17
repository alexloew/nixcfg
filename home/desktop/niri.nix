# Niri Home Configuration
# Window manager settings and keybinds
# DankMaterialShell handles layout, colors, keybinds, bar, launcher, notifications
# See: https://danklinux.com/docs/dankmaterialshell/compositors

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.niri-flake.homeModules.niri
  ];
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

  # Niri configuration (KDL format)
  xdg.configFile."niri/config.kdl".text = ''
    // DankMaterialShell include files
    // DMS manages layout (gaps, radius), colors, keybinds, and alt-tab
    include "dms/colors.kdl"
    include "dms/layout.kdl"
    include "dms/alttab.kdl"
    include "dms/binds.kdl"

    // Environment variables for NVIDIA + Wayland
    environment {
        NIXOS_OZONE_WL "1"
        ELECTRON_OZONE_PLATFORM_HINT "auto"
    }

    // Input configuration
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }

        touchpad {
            natural-scroll
            tap
        }

        mouse {
            // accel-speed 0.0
        }

        focus-follows-mouse max-scroll-amount="0%"
    }

    // Output / monitor configuration
    output "eDP-1" {
        scale 2.0
    }

    // Decorations
    window-rule {
        opacity 0.95
        clip-to-geometry true
        geometry-corner-radius 10 10 10 10
    }

    // Force full opacity for browsers and Slack
    window-rule {
        match app-id=r#"^Google-chrome$"#
        match app-id=r#"^Slack$"#
        opacity 1.0
    }

    // User key bindings (in addition to DMS-managed binds)
    binds {
        // Application launchers
        Mod+Return { spawn "ghostty"; }
        Mod+B { spawn "firefox"; }

        // Screenshots (saved to ~/Pictures/Screenshots)
        Print { spawn "sh" "-c" "grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"; }
        Mod+Print { spawn "sh" "-c" "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"; }
        // Screenshot to clipboard
        Mod+Shift+S { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }

        // Window management
        Mod+Q { close-window; }
        Mod+Shift+M { quit; }
        Mod+V { toggle-window-floating; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // Focus movement (vim-style)
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-or-workspace-up; }
        Mod+J { focus-window-or-workspace-down; }

        // Arrow key focus movement
        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-or-workspace-up; }
        Mod+Down { focus-window-or-workspace-down; }

        // Move windows (vim-style)
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+K { move-window-up-or-to-workspace-up; }
        Mod+Shift+J { move-window-down-or-to-workspace-down; }

        // Arrow key move windows
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up { move-window-up-or-to-workspace-up; }
        Mod+Shift+Down { move-window-down-or-to-workspace-down; }

        // Column width adjustments
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        // Preset column widths
        Mod+R { switch-preset-column-width; }

        // Consume / expel windows (merge columns)
        Mod+BracketLeft { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }

        // Workspace switching
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }

        // Move window to workspace
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }

        // Scroll through workspaces
        Mod+WheelScrollDown { focus-workspace-down; }
        Mod+WheelScrollUp { focus-workspace-up; }

        // Mouse window management
        Mod+WheelScrollRight { focus-column-right; }
        Mod+WheelScrollLeft { focus-column-left; }
    }

    // Cursor settings
    cursor {
        xcursor-theme "Adwaita"
        xcursor-size 24
    }

    // Screenshot path
    screenshot-path "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"
  '';
}
