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

| Key | Workspace | Preferred output | Application |
|---|---|---|---|
| `Super+1` | `notes` | AW2725DF / left, top | Obsidian |
| `Super+2` | `media` | AW2725DF / left, below `notes` | Spotify |
| `Super+3` | `web` | AW3423DWF / center, top | Chrome |
| `Super+4` | `terminal` | AW3423DWF / center, below `web` | Ghostty |
| `Super+5` | `chat` | `eDP-1` / right | Slack |

`Super+Shift+1` through `Super+Shift+5` move a column to the corresponding named workspace.

When docked, Niri has three side-by-side physical workspace columns:

- **Left:** `notes` above `media` — Obsidian above Spotify.
- **Center:** `web` above `terminal` — Chrome above Ghostty.
- **Right:** `chat` — Slack.

With only the laptop panel connected, Niri cannot preserve multiple physical workspace columns. The reconciler therefore reproduces the accepted overview layout, excluding the extra empty workspace at the top:

| Index | Workspace | Windows |
|---:|---|---|
| 1 | `media` | Spotify |
| 2 | `web` | Obsidian, Chrome and Slack as horizontal window columns |
| 3 | `terminal` | Ghostty |

The dock-only `notes` and `chat` names are removed after Obsidian and Slack merge into `web`. Niri retains its required empty spare workspace. When DP-1 and DP-2 return, the reconciler restores the five workspaces into their three preferred physical workspace columns.

## Lid behavior

`system/hardware.nix` configures logind to suspend on lid close when undocked and to ignore the lid while docked. Niri consumes kernel lid events directly and owns the laptop panel's disconnect/reconnect state; its topology changes drive the Home Manager display watcher.

The greeter's Niri configuration keeps the laptop panel logically available while the lid is closed. This prevents a lid-closed, undocked boot from starting DMS with zero outputs. The setting is greeter-only; the logged-in session retains the normal lid and topology behavior below.

On resume, DMS keeps running and restores its own Wayland surfaces. The system does not restart graphical user services unconditionally: removing DMS's active lock surface makes Niri display its solid-red security fallback, while starting the display reconciler before any output is active creates a restart loop. Niri's output topology event starts reconciliation when the panel is available; a zero-output run exits successfully and defers to that event.

There is deliberately no acpid-to-user-service lid bridge and no explicit `niri msg output eDP-1 off/on` pair. A lid-open event can arrive while systemd still has the user slice frozen; the user-manager call then fails, and an earlier explicit `off` would survive resume and leave Niri with no active output. Letting Niri consume the kernel lid state directly makes panel wake independent of user-service timing.

DMS system sound effects are disabled as a suspend-safety workaround. When AC or a dock disappears, Qt Multimedia can leave DMS's QFFmpeg audio-renderer thread attached to the removed PipeWire sink and crash Quickshell after resume. This does not disable application audio, DMS volume controls or media widgets.

### Docked lid close

1. Niri disconnects `eDP-1` from the kernel lid state.
2. The topology watcher observes the changed active-output signature.
3. The topology-aware display service restarts.
4. The left and center workspace columns remain unchanged.
5. Slack moves into a full-width window column to the right of Chrome on `web`.
6. The empty displaced `chat` workspace is removed and the previously active window regains focus.

### Lid open

1. Niri reconnects `eDP-1` directly from the kernel lid state.
2. The topology watcher restarts the display reconciler.
3. `chat` is recreated on the laptop panel.
4. Slack returns to `chat`.
5. The normal docked application layout is restored.

## Startup applications

`configure-displays.service` starts with the graphical session. It:

1. discovers and validates the socket belonging to the live Niri process;
2. detects connected outputs;
3. launches only missing Spotify, Obsidian, Chrome, Ghostty and Slack processes;
4. creates three physical workspace columns when docked or the accepted collapsed laptop layout;
5. normalizes workspace order, window-column order and sizes;
6. removes empty named workspaces that do not belong in the active topology;
7. restores the previously focused window; and
8. keeps `swaybg` running as the service process.

`display-topology-watcher.service` subscribes to Niri's event stream. Niri has no dedicated output-change event, so the watcher observes `WorkspacesChanged`, compares the active-output signature, and restarts the reconciler only when that signature changes. Both processes count only JSON outputs whose `logical` field is non-null; Niri keeps a powered-off laptop panel in its output inventory. It also tracks window IDs and reconciles when one of the five managed apps opens; layout changes to an existing window do not retrigger it.

Application placement uses observed Wayland app IDs:

| Application | App ID |
|---|---|
| Spotify | `spotify` |
| Obsidian | `md.Obsidian` |
| Chrome | `google-chrome` |
| Ghostty | `com.mitchellh.ghostty` |
| Slack | `slack` (rules also accept `Slack`) |

Window rules provide initial placement. The reconciler normalizes existing windows whenever it starts, making topology changes idempotent. Evaluation alone does not move windows.

## Configuration ownership

| Concern | File |
|---|---|
| Output mode, scale and position | `home/desktop/niri.nix` |
| Named workspace/output mapping | `home/desktop/niri.nix` |
| App placement and opacity | `home/desktop/niri.nix` |
| Lid suspend policy and native panel handling | `system/hardware.nix` and Niri |
| Topology watcher, app reflow, wallpaper and startup | `home/desktop/displays.nix` |
| DMS bar, theme and idle policy | `home/desktop/dms.nix` |
| Greeter | `system/desktop/dms-greeter.nix` |
| P16s hardware profile, GPU drivers and PRIME offload | `flake.nix` (`nixos-hardware`) |
| NVIDIA suspend and runtime power policy | `system/nvidia.nix` |

There is deliberately no DRM hotplug udev rule that restarts `configure-displays.service`. A previous rule formed a modeset/uevent restart loop during boot. Niri now applies declared output configuration natively when outputs connect.

## Inspect the live layout

```bash
niri msg outputs
niri msg --json workspaces | jq .
niri msg --json windows | jq .
systemctl --user status configure-displays.service
systemctl --user status display-topology-watcher.service
```

Validate generated KDL before activation:

```bash
niri validate --config /path/to/generated/config.kdl
```

See [`cheatsheet.md`](cheatsheet.md) for navigation and screenshot keybindings.
