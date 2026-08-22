# Niri Home Configuration
# Window manager settings and keybinds
# DankMaterialShell handles layout, colors, bar, launcher, notifications, and its
# own IPC keybinds; window/navigation keybinds live in the `binds` block below.
# Keybinds must come from a single source — see dms.nix for why "binds" is not
# included from DMS (niri rejects duplicate binds to the same key).
# See: https://danklinux.com/docs/dankmaterialshell/compositors

{ pkgs, niriPackage, ... }:

let
  # Same upstream niri build as the running compositor and greeter.
  niri = niriPackage;
in
{
  # Install supporting tools
  home.packages = with pkgs; [
    swaylock      # Screen locker — break-glass only; DMS is the primary locker
    swaybg        # Wallpaper renderer
    grim          # Screenshots (used for region-to-clipboard)
    slurp         # Region selection (used for screenshot-to-clipboard)
    wl-clipboard  # Clipboard support
    # Idle handling is DMS's native idle daemon (see home/desktop/dms.nix);
    # swayidle is no longer used.
  ];

  # Home Manager owns the generated KDL; NixOS owns compositor/session setup.
  wayland.windowManager.niri = {
    enable = true;
    package = niriPackage;
    systemd.enable = false;
    portalPackage = null;

    settings = {
      # Repeated top-level nodes must be expressed as ordered KDL children.
      _children = [
        # Output configuration — niri requires connector names, not EDID strings.
        # Current hardware: DP-1=AW3423DWF (ultrawide), DP-2=AW2725DF (27-inch)
        {
          output = {
            _args = [ "DP-1" ];
            scale = 1.0;
            transform = "normal";
            position._props = { x = 2560; y = 0; };
            mode = "3440x1440@99.982000";
          };
        }
        {
          output = {
            _args = [ "DP-2" ];
            scale = 1.0;
            transform = "normal";
            position._props = { x = 0; y = 0; };
            mode = "2560x1440@143.969000";
          };
        }
        {
          output = {
            _args = [ "eDP-1" ];
            scale = 2.0;
            transform = "normal";
          };
        }

        # Window rules: opacity plus per-application overrides.
        {
          window-rule._children = [
            { clip-to-geometry = true; }
            { opacity = 0.95; }
          ];
        }
        {
          window-rule._children = [
            { match._props.is-active = false; }
            { opacity = 0.90; }
          ];
        }
        {
          window-rule._children = [
            { match._props.app-id = "^com\\.mitchellh\\.ghostty$"; }
            { match._props.app-id = "^Alacritty$"; }
            { match._props.app-id = "^kitty$"; }
            { match._props.app-id = "^foot$"; }
            { opacity = 0.95; }
          ];
        }
        {
          window-rule._children = [
            { match._props.app-id = "^google-chrome$"; }
            { match._props.app-id = "^firefox$"; }
            { match._props.app-id = "^Slack$"; }
            { match._props.app-id = "^mpv$"; }
            { match._props.app-id = "^vlc$"; }
            { opacity = 1.0; }
          ];
        }
        {
          window-rule._children = [
            { match._props.app-id = "^google-chrome$"; }
            { match._props.app-id = "^com\\.mitchellh\\.ghostty$"; }
            { open-maximized = true; }
          ];
        }
        {
          window-rule._children = [
            { match._props.app-id = "^Slack$"; }
            { open-maximized = true; }
          ];
        }

        # Layer rules: DMS controls its own background alpha.
        {
          layer-rule._children = [
            { match._props.namespace = "^dms:bar$"; }
            { opacity = 1.0; }
          ];
        }
        {
          layer-rule._children = [
            { match._props.namespace = "^quickshell$"; }
            { opacity = 1.0; }
          ];
        }
      ];

      # Environment variables for NVIDIA and Wayland applications.
      environment = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        # niri isn't launched with `--session` here (greetd/dms-greeter), so it
        # doesn't set this itself; portals and apps use it to pick a backend.
        XDG_CURRENT_DESKTOP = "niri";
      };

      prefer-no-csd = { };
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      input = {
        keyboard = {
          xkb = {
            layout = "us";
            model = "";
            rules = "";
            variant = "";
          };
          repeat-delay = 600;
          repeat-rate = 25;
          track-layout = "global";
        };

        touchpad = {
          natural-scroll = { };
          tap = { };
        };

        mouse.natural-scroll = { };
        focus-follows-mouse._props.max-scroll-amount = "0%";
      };

      # DMS's layout include follows this generated configuration and overrides
      # the values it owns (gaps, border/focus widths, and corner radius).
      layout = {
        gaps = 16;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };

        focus-ring = {
          width = 2;
          active-color = "#4a4a4a";
          inactive-color = "#252525";
        };

        border.off = { };

        shadow = {
          on = { };
          offset._props = { x = 0; y = 2; };
          softness = 12;
          spread = 3;
          draw-behind-window = false;
          color = "#0d0d0dcc";
          inactive-color = "#0d0d0d88";
        };

        default-column-width.proportion = 0.5;
        preset-column-widths._children = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
          { proportion = 1.0; }
        ];
        center-focused-column = "never";
      };

      cursor = {
        xcursor-theme = "Adwaita";
        xcursor-size = 24;
      };

      animations = {
        workspace-switch.spring._props = {
          damping-ratio = 0.8;
          stiffness = 1000;
          epsilon = 0.0001;
        };
        horizontal-view-movement.spring._props = {
          damping-ratio = 0.8;
          stiffness = 800;
          epsilon = 0.0001;
        };
        window-open = {
          duration-ms = 200;
          curve = "ease-out-cubic";
        };
        window-close = {
          duration-ms = 150;
          curve = "ease-out-cubic";
        };
        window-movement.spring._props = {
          damping-ratio = 0.8;
          stiffness = 800;
          epsilon = 0.0001;
        };
        window-resize.spring._props = {
          damping-ratio = 0.8;
          stiffness = 800;
          epsilon = 0.0001;
        };
      };

      # User key bindings. DMS IPC keybinds are declared here too (see dms.nix)
      # so this generated file remains the sole binding authority.
      binds = {
        # Application launchers
        "Mod+Return".spawn = [ "ghostty" ];
        "Mod+B".spawn = [ "firefox" ];

        # DMS IPC keybinds are declared directly so the generated Home Manager
        # config remains the only binding authority.
        "Mod+Space" = {
          _props.hotkey-overlay-title = "Toggle Application Launcher";
          spawn = [ "dms" "ipc" "spotlight" "toggle" ];
        };
        "Mod+N" = {
          _props.hotkey-overlay-title = "Toggle Notification Center";
          spawn = [ "dms" "ipc" "notifications" "toggle" ];
        };
        "Mod+Comma" = {
          _props.hotkey-overlay-title = "Toggle Settings";
          spawn = [ "dms" "ipc" "settings" "toggle" ];
        };
        "Mod+P" = {
          _props.hotkey-overlay-title = "Toggle Notepad";
          spawn = [ "dms" "ipc" "notepad" "toggle" ];
        };
        "Mod+V" = {
          _props.hotkey-overlay-title = "Toggle Clipboard Manager";
          spawn = [ "dms" "ipc" "clipboard" "toggle" ];
        };
        "Mod+X" = {
          _props.hotkey-overlay-title = "Toggle Power Menu";
          spawn = [ "dms" "ipc" "powermenu" "toggle" ];
        };
        "Mod+M" = {
          _props.hotkey-overlay-title = "Toggle Process List";
          spawn = [ "dms" "ipc" "processlist" "toggle" ];
        };
        "Mod+Alt+N" = {
          _props = {
            allow-when-locked = true;
            hotkey-overlay-title = "Toggle Night Mode";
          };
          spawn = [ "dms" "ipc" "night" "toggle" ];
        };
        "Super+Alt+L" = {
          _props.hotkey-overlay-title = "Toggle Lock Screen";
          spawn = [ "dms" "ipc" "lock" "lock" ];
        };
        "XF86AudioLowerVolume" = {
          _props.allow-when-locked = true;
          spawn = [ "dms" "ipc" "audio" "decrement" "3" ];
        };
        "XF86AudioRaiseVolume" = {
          _props.allow-when-locked = true;
          spawn = [ "dms" "ipc" "audio" "increment" "3" ];
        };
        "XF86AudioMute" = {
          _props.allow-when-locked = true;
          spawn = [ "dms" "ipc" "audio" "mute" ];
        };
        "XF86AudioMicMute" = {
          _props.allow-when-locked = true;
          spawn = [ "dms" "ipc" "audio" "micmute" ];
        };
        "XF86MonBrightnessUp" = {
          _props.allow-when-locked = true;
          spawn = [ "dms" "ipc" "brightness" "increment" "5" "" ];
        };
        "XF86MonBrightnessDown" = {
          _props.allow-when-locked = true;
          spawn = [ "dms" "ipc" "brightness" "decrement" "5" "" ];
        };

        # Screenshots
        "Mod+S".screenshot-screen = { };
        "Mod+Alt+S".screenshot = { };
        "Mod+Shift+Alt+S".screenshot-window = { };
        "Mod+Shift+S".spawn = [ "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy" ];

        # Window management
        "Mod+Q".close-window = { };
        "Mod+Shift+M".quit = { };
        "Mod+Shift+V".toggle-window-floating = { };
        "Mod+F".maximize-column = { };
        "Mod+Shift+F".fullscreen-window = { };

        # Focus movement (vim-style)
        "Mod+H".focus-column-left = { };
        "Mod+L".focus-column-right = { };
        "Mod+K".focus-window-or-workspace-up = { };
        "Mod+J".focus-window-or-workspace-down = { };

        # Arrow key focus movement
        "Mod+Left".focus-column-left = { };
        "Mod+Right".focus-column-right = { };
        "Mod+Up".focus-window-or-workspace-up = { };
        "Mod+Down".focus-window-or-workspace-down = { };

        # Move windows (vim-style)
        "Mod+Shift+H".move-column-left = { };
        "Mod+Shift+L".move-column-right = { };
        "Mod+Shift+K".move-window-up-or-to-workspace-up = { };
        "Mod+Shift+J".move-window-down-or-to-workspace-down = { };

        # Arrow key move windows
        "Mod+Shift+Left".move-column-left = { };
        "Mod+Shift+Right".move-column-right = { };
        "Mod+Shift+Up".move-window-up-or-to-workspace-up = { };
        "Mod+Shift+Down".move-window-down-or-to-workspace-down = { };

        # Column width adjustments
        "Mod+Minus".set-column-width = "-10%";
        "Mod+Equal".set-column-width = "+10%";
        "Mod+Shift+Minus".set-window-height = "-10%";
        "Mod+Shift+Equal".set-window-height = "+10%";

        "Mod+R".switch-preset-column-width = { };
        "Mod+BracketLeft".consume-or-expel-window-left = { };
        "Mod+BracketRight".consume-or-expel-window-right = { };

        # Workspace switching
        "Mod+1".focus-workspace = 1;
        "Mod+2".focus-workspace = 2;
        "Mod+3".focus-workspace = 3;
        "Mod+4".focus-workspace = 4;
        "Mod+5".focus-workspace = 5;
        "Mod+6".focus-workspace = 6;
        "Mod+7".focus-workspace = 7;
        "Mod+8".focus-workspace = 8;
        "Mod+9".focus-workspace = 9;
        "Mod+0".focus-workspace = 10;

        # Move windows to workspaces
        "Mod+Shift+1".move-column-to-workspace = 1;
        "Mod+Shift+2".move-column-to-workspace = 2;
        "Mod+Shift+3".move-column-to-workspace = 3;
        "Mod+Shift+4".move-column-to-workspace = 4;
        "Mod+Shift+5".move-column-to-workspace = 5;
        "Mod+Shift+6".move-column-to-workspace = 6;
        "Mod+Shift+7".move-column-to-workspace = 7;
        "Mod+Shift+8".move-column-to-workspace = 8;
        "Mod+Shift+9".move-column-to-workspace = 9;
        "Mod+Shift+0".move-column-to-workspace = 10;

        "MouseMiddle".toggle-overview = { };
        "Mod+WheelScrollDown".focus-workspace-down = { };
        "Mod+WheelScrollUp".focus-workspace-up = { };
        "Mod+WheelScrollRight".focus-column-right = { };
        "Mod+WheelScrollLeft".focus-column-left = { };
      };

      gestures.hot-corners.off = { };

      # Bring up the systemd graphical session ourselves. The greetd/DMS login
      # starts bare niri rather than niri-session, so niri does not activate
      # graphical-session.target on its own.
      spawn-at-startup = [
        "sh"
        "-c"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIRI_SOCKET; systemctl --user start niri-session.target"
      ];
    };

    # DMS owns these runtime-generated fragments. They follow the base config so
    # its layout values override ours. Binds, outputs, and window rules remain
    # excluded to avoid duplicate or competing configuration authorities.
    extraConfig = ''
      include optional=true "dms/alttab.kdl"
      include optional=true "dms/layout.kdl"
    '';
  };

  # Intermediate target started from niri's spawn-at-startup. It exists only to
  # pull in graphical-session.target, which refuses a direct manual start.
  systemd.user.targets.niri-session = {
    Unit = {
      Description = "niri session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  # Idle handling (display-off, suspend-on-battery, lock) is DMS's native idle
  # daemon, configured in home/desktop/dms.nix. No standalone service here.

  # Lid-close handler: toggle eDP-1 off/on via niri msg.
  systemd.user.services.lid-handler = {
    Unit.Description = "Toggle eDP-1 output on lid close/open";
    Service = let
      script = pkgs.writeShellScript "lid-handler" ''
        state=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null || \
                cat /proc/acpi/button/lid/LID/state 2>/dev/null)
        if echo "$state" | grep -q "closed"; then
          ${niri}/bin/niri msg output eDP-1 off
        else
          ${niri}/bin/niri msg output eDP-1 on
        fi
      '';
    in {
      Type = "oneshot";
      ExecStart = "${script}";
    };
  };

  home.file.".local/share/wallpapers/earthrise.JPG".source = ./wallpapers/earthrise.JPG;
}
