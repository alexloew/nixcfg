# Hyprland Home Configuration
# Window manager settings and keybinds
# DankMaterialShell handles the bar, launcher, notifications, etc.

{ config, pkgs, lib, ... }:

{
  # Hyprland user configuration
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # Monitor configuration (adjust to your setup)
      monitor = [
        ",preferred,auto,2"  # 2x HiDPI scaling
      ];

      # Environment variables for NVIDIA + Wayland (offload mode)
      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
        "NIXOS_OZONE_WL,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      # DMS handles startup apps (bar, notifications, etc.)
      exec-once = [
        # DMS starts automatically via its module
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };

      # General appearance
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(313244aa)";
        layout = "dwindle";
      };

      # Decorations (rounded corners, blur, shadows, transparency)
      decoration = {
        rounding = 10;

        # Window transparency
        active_opacity = 0.95;
        inactive_opacity = 0.85;
        fullscreen_opacity = 1.0;

        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          xray = false;
          noise = 0.02;
          contrast = 0.9;
          brightness = 0.8;
          vibrancy = 0.2;
          popups = false;
          special = true;          # Blur special workspaces
        };

      # Make DMS bar and overlays transparent with blur
      layerrule = [
        "blur, dms:bar"
        "ignorealpha 0.3, dms:bar"
        "blur, quickshell"
        "ignorealpha 0.3, quickshell"
      ];
        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
          color = "rgba(1a1a2eee)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Key bindings
      "$mod" = "SUPER";

      bind = [
        # Application launchers
        "$mod, Return, exec, ghostty"
        "$mod, B, exec, firefox"

        # DMS spotlight launcher (replaces wofi/rofi)
        "$mod, D, exec, dms ipc call spotlight toggle"

        # Screenshots (saved to ~/Pictures/Screenshots)
        ", Print, exec, grim ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S').png"
        "$mod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S').png"
        "$mod SHIFT, Print, exec, grim -g \"$(hyprctl -j activewindow | jq -r '.at[0],.at[1],.size[0],.size[1]' | tr '\\n' ' ' | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\" ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S').png"
        # Screenshots to clipboard
        "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Window management
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, F, fullscreen"

        # Focus movement
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"

        # Workspace switching
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ];

      # Window rules - disable transparency for Chromium-based apps to prevent artifacts
      windowrulev2 = [
        "opacity 1.0 override 1.0 override, class:^(Google-chrome)$"
        "opacity 1.0 override 1.0 override, class:^(Slack)$"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
