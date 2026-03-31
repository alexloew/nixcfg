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
│   ├── desktop/
│   │   ├── common.nix       # Shared desktop settings
│   │   ├── gnome.nix        # GNOME + GDM
│   │   ├── hyprland.nix     # Hyprland compositor
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
    │   ├── dms.nix          # DankMaterialShell + Niri integration
    │   ├── fonts.nix        # Nerd fonts
    │   ├── gnome.nix        # GNOME extensions
    │   ├── hyprland.nix     # Hyprland config
    │   ├── idle.nix         # Idle management
    │   └── niri.nix         # Niri config + DMS includes
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
| `Super+D` | App launcher (DMS Spotlight) |
| `Super+B` | Firefox |
| `Super+Q` | Close window |
| `Super+F` | Maximize column |
| `Super+Shift+F` | Fullscreen |
| `Super+V` | Toggle floating |
| `Super+1-9` | Switch workspace |
| `Super+Shift+1-9` | Move window to workspace |
| `Super+H/J/K/L` | Vim-style focus |
| `Super+Shift+H/J/K/L` | Vim-style move |
| `Super+Shift+S` | Screenshot region to clipboard |

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

## Adding a New Host

1. Create `hosts/newhost/default.nix` and `hardware.nix`
2. Add to `flake.nix`:
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     modules = [ ./hosts/newhost ];
   };
   ```
3. Build: `sudo nixos-rebuild switch --flake .#newhost`
