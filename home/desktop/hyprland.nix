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
        ",preferred,auto,1"  # Default: auto-detect
      ];

      # DMS handles startup apps (bar, notifications, etc.)
      # Add any additional startup apps here
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

      # Decorations (rounded corners, blur, shadows)
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
          new_optimizations = true;
        };
        shadow = {
          enabled = true;
          range = 8;
          render_power = 2;
          color = "rgba(1a1a1aee)";
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

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
