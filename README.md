# nixcfg

NixOS configuration using flakes with dendritic (tree-like) organization.

## Structure

```
.
├── flake.nix                # Entry point
├── docs/
│   └── cheatsheet.md        # Tmux + Helix keybind reference
├── hosts/
│   └── nixos/
│       ├── default.nix      # System entry point
│       └── hardware.nix     # Hardware configuration
├── system/                  # NixOS system modules
│   ├── boot.nix             # Systemd-boot, EFI, LUKS
│   ├── containers.nix       # Rootless Podman (distrobox backend)
│   ├── desktop/
│   │   ├── common.nix       # Shared desktop settings
│   │   ├── gnome.nix        # GNOME + GDM
│   │   └── niri.nix         # Niri compositor
│   ├── hardware.nix         # Audio (PipeWire), printing
│   ├── locale.nix           # Timezone, i18n
│   ├── network.nix          # NetworkManager
│   ├── nix.nix              # Nix settings, flakes
│   ├── nvidia.nix           # NVIDIA drivers
│   ├── tpm.nix              # TPM support
│   ├── users.nix            # User accounts
│   └── virt.nix             # Virtualization (libvirt/QEMU/KVM)
└── home/                    # Home-manager modules
    ├── apps/
    │   ├── cli.nix          # CLI tools (lazygit, yazi, gh, ripgrep, fzf…)
    │   └── gui.nix          # Desktop apps (Ghostty, Slack, Spotify…)
    ├── desktop/
    │   ├── displays.nix     # EDID-based display + wallpaper service
    │   ├── dms.nix          # DankMaterialShell + Niri integration
    │   ├── fonts.nix        # Nerd fonts
    │   ├── gnome.nix        # GNOME extensions
    │   ├── idle.nix         # Idle management
    │   └── niri.nix         # Niri config + DMS includes
    ├── dev/
    │   ├── distrobox.nix    # distrobox config + box definitions
    │   ├── go.nix           # Go toolchain
    │   └── herdr.nix        # herdr workspace manager
    ├── editors/
    │   └── helix.nix        # Helix editor + LSPs
    └── shell/
        ├── bash.nix         # Shell aliases
        ├── git.nix          # Git config
        ├── ssh.nix          # SSH client
        ├── starship.nix     # Prompt
        ├── tmux.nix         # Terminal multiplexer
        └── zsh.nix          # Zsh config
```

## Usage

### Apply configuration

```bash
sudo nixos-rebuild switch --flake .#nixos
```

### Update flake inputs

```bash
nix flake update
```

## Desktop

- **Compositor**: Niri (scrollable tiling Wayland compositor)
- **Shell**: [DankMaterialShell](https://danklinux.com/docs/dankmaterialshell/) (bar, launcher, notifications)
- **Fallback**: GNOME (select from GDM)

DMS manages layout (gaps, radius), colors, keybinds, and alt-tab via config includes in `~/.config/niri/dms/`. User keybinds are defined in `home/desktop/niri.nix`.

### Keybinds

| Keys | Action |
|------|--------|
| `Super+Return` | Terminal (Ghostty) |
| `Super+Space` | App launcher (DMS Spotlight) |
| `Super+B` | Firefox |
| `Super+Q` | Close window |
| `Super+F` | Maximize column |
| `Super+Shift+F` | Fullscreen |
| `Super+Shift+V` | Toggle floating |
| `Super+1-9` | Switch workspace |
| `Super+Shift+1-9` | Move window to workspace |
| `Super+H/J/K/L` | Vim-style focus |
| `Super+Shift+H/J/K/L` | Vim-style move |
| `Super+S` | Screenshot current screen to file |
| `Super+Alt+S` | Screenshot interactive region to file |
| `Super+Shift+S` | Screenshot region to clipboard |
| `Super+Shift+Alt+S` | Screenshot focused window to file |

## Editor & Terminal Workflow

**Editor**: Helix (modal, LSP-first, no plugins needed)  
**Multiplexer**: tmux with `Ctrl+\` prefix  
**File manager**: yazi — open with `Ctrl+\` then `y`  
**Git TUI**: lazygit — open with `Ctrl+\` then `g`  
**GitHub CLI**: `gh` for PRs, issues, and CI from the terminal

See [`docs/cheatsheet.md`](./docs/cheatsheet.md) for the full keybind reference.

### Helix LSPs

| Language | Servers |
|----------|---------|
| Python | ruff, basedpyright, harper-ls |
| Rust | rust-analyzer, harper-ls |
| Nix | nil |
| Markdown | marksman, harper-ls |
| YAML | yaml-language-server |
| SQL | sqlfluff (formatter) |

## Virtualization

libvirt/QEMU/KVM with UEFI and TPM support for testing NixOS ISOs.

```bash
# Launch an ISO in virt-manager (GUI)
virt-manager

# Or from the CLI
virt-install \
  --name nixos-test \
  --ram 4096 \
  --vcpus 2 \
  --cdrom /path/to/nixos.iso \
  --disk size=20 \
  --boot uefi
```

## Containers (distrobox)

Rootless Podman (`system/containers.nix`) backs [distrobox](https://distrobox.it/)
(`home/dev/distrobox.nix`) for tooling that wants a conventional FHS distro —
`apt` packages, prebuilt binaries, vendor installers. Boxes share `$HOME` and
bind-mount `/nix` read-only, so host dotfiles and Nix binaries work inside.

Defaults live in `~/.config/distrobox/distrobox.conf`; three boxes (`ubuntu`,
`fedora`, `arch`) are declared in `~/.config/distrobox/assemble.ini`.

Boxes are graphical, not headless — distrobox shares the Wayland/X11 sockets,
dbus, audio and `/dev/dri`, so GUI apps installed inside run against the host
session. `container_generate_entry=1` adds their launcher entries to the host.
NVIDIA passthrough (`nvidia=true`) is on for CUDA / explicit dGPU offload; the
display itself is driven by the Intel iGPU in PRIME offload mode.

```bash
# Create the declared boxes (idempotent; skips existing ones)
distrobox assemble create --all

# Enter / list / remove
distrobox enter arch
distrobox list
distrobox rm arch

# Ad-hoc box outside the assemble file
distrobox create --name tumbleweed --image registry.opensuse.org/opensuse/tumbleweed:latest

# Export a GUI app installed in a box to the host launcher
distrobox enter arch -- distrobox-export --app gimp

# Run a host command from inside a box
distrobox-host-exec systemctl status

# docker is aliased to podman
docker ps
```

Boxes are mutable state, not declarative: editing `assemble.ini` does not
rebuild an existing box. Use `distrobox assemble create --replace --all` to
recreate them from the updated definitions.

## Adding a New Host

1. Create `hosts/newhost/default.nix` and `hardware.nix`
2. Add to `flake.nix`:
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     modules = [ ./hosts/newhost ];
   };
   ```
3. Build: `sudo nixos-rebuild switch --flake .#newhost`
