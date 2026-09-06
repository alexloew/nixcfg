# Desktop and display behavior

## Stack

The primary desktop is:

- **Login:** greetd with the DankMaterialShell greeter
- **Compositor:** Niri
- **Shell:** DankMaterialShell (DMS)
- **Fallback session:** GNOME remains installed and selectable
- **Graphics:** Intel iGPU drives displays; the NVIDIA RTX 500 Ada is available through PRIME offload

Niri owns outputs, workspaces, window rules and navigation. DMS owns the bar, launcher, notifications, theming, idle policy and its runtime layout fragments.

## Display topology

| Role | Output | Hardware | Logical position | Mode |
|---|---|---|---:|---|
| Left | `DP-2` | Dell AW2725DF | `0,0` | 2560×1440 at 143.969 Hz |
| Center | `DP-1` | Dell AW3423DWF | `2560,0` | 3440×1440 at 99.982 Hz |
| Right | `eDP-1` | Samsung laptop panel | `6000,0` when all outputs are present | 3840×2400 at scale 2 |

Output geometry is declared in `home/desktop/niri.nix`. `home/desktop/displays.nix` detects models only to assign wallpapers; it does not issue mode or position changes.

## Named workspaces

| Key | Workspace | Preferred output | Applications |
|---|---|---|---|
| `Super+1` | `media` | AW2725DF / left | Spotify, then Obsidian in a 40/60 column split |
| `Super+2` | `web` | AW3423DWF / center | Chrome; startup focus |
| `Super+3` | `terminal` | AW3423DWF / center, below `web` | Ghostty |
| `Super+4` | `chat` | `eDP-1` / right | Slack |

`Super+Shift+1` through `Super+Shift+4` move a column to the corresponding named workspace.

Named workspaces remember their preferred outputs. If an external display disconnects, Niri moves its workspaces temporarily to an available output. They return when the preferred display reconnects.

With only the laptop panel connected, the workspace stack remains:

1. `media` — Spotify and Obsidian
2. `web` — Chrome and focus
3. `terminal` — Ghostty below `web`
4. `chat` — Slack

On one output, Niri presents these as a vertical workspace stack rather than simultaneous left, center and right regions.

## Lid behavior

`system/hardware.nix` configures logind to suspend on lid close when undocked and to ignore the lid while docked. A udev rule starts the Home Manager `lid-handler` user service whenever the lid state changes.

### Docked lid close

1. Turn off `eDP-1` through Niri.
2. Move Slack from `chat` to `web` without following focus.
3. Place Slack as the rightmost column beside Chrome.
4. Focus `web` and its first column, leaving Chrome focused.
5. Leave Ghostty on the separate `terminal` workspace below.

### Lid open

1. Turn on `eDP-1`.
2. Allow the named `chat` workspace to return to its preferred output.
3. Move Slack back to `chat` without stealing focus.

The startup display service also invokes the lid handler after launching missing applications. This covers sessions that begin with the lid already closed.

## Startup applications

`configure-displays.service` starts with the graphical session. It:

1. waits for Niri IPC;
2. detects connected outputs for wallpaper assignment;
3. reads open Niri windows;
4. launches only missing instances of Spotify, Obsidian, Chrome, Ghostty and Slack;
5. lets window rules place them on named workspaces;
6. applies the current lid state; and
7. keeps `swaybg` running as the service process.

Application placement uses observed Wayland app IDs:

| Application | App ID |
|---|---|
| Spotify | `spotify` |
| Obsidian | `md.Obsidian` |
| Chrome | `google-chrome` |
| Ghostty | `com.mitchellh.ghostty` |
| Slack | `slack` (rules also accept `Slack`) |

Window rules apply when windows open. Existing windows are not retroactively moved merely because a new configuration evaluates; use a fresh session or relaunch applications when first testing a placement change.

## Configuration ownership

| Concern | File |
|---|---|
| Output mode, scale and position | `home/desktop/niri.nix` |
| Named workspace/output mapping | `home/desktop/niri.nix` |
| App placement and opacity | `home/desktop/niri.nix` |
| Lid reflow | `home/desktop/niri.nix` and `system/hardware.nix` |
| Wallpaper and startup launch | `home/desktop/displays.nix` |
| DMS bar, theme and idle policy | `home/desktop/dms.nix` |
| Greeter | `system/desktop/dms-greeter.nix` |
| NVIDIA PRIME offload | `system/nvidia.nix` |

There is deliberately no DRM hotplug udev rule that restarts `configure-displays.service`. A previous rule formed a modeset/uevent restart loop during boot. Niri now applies declared output configuration natively when outputs connect.

## Inspect the live layout

```bash
niri msg outputs
niri msg --json workspaces | jq .
niri msg --json windows | jq .
systemctl --user status configure-displays.service
systemctl --user status lid-handler.service
```

Validate generated KDL before activation:

```bash
niri validate --config /path/to/generated/config.kdl
```

See [`cheatsheet.md`](cheatsheet.md) for navigation and screenshot keybindings.
