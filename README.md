# nixcfg

NixOS configuration using flakes with dendritic (tree-like) organization.

## Structure

```
.
├── flake.nix                # Entry point
├── hosts/                   # Machine-specific configs
│   └── nixos/
│       ├── default.nix      # System entry point
│       └── hardware.nix     # Hardware configuration
├── system/                  # NixOS system modules
│   ├── boot.nix
│   ├── desktop/
│   │   ├── common.nix       # Shared desktop settings
│   │   ├── gnome.nix        # GNOME + GDM
│   │   └── hyprland.nix     # Hyprland compositor
│   ├── hardware.nix         # Audio, printing
│   ├── locale.nix           # Timezone, i18n
│   ├── network.nix          # NetworkManager
│   ├── nix.nix              # Nix settings
│   └── users.nix            # User accounts
└── home/                    # Home-manager modules
    ├── apps/
    │   ├── cli.nix          # CLI tools
    │   └── gui.nix          # Desktop apps
    ├── desktop/
    │   ├── dms.nix          # DankMaterialShell
    │   ├── fonts.nix        # Nerd fonts
    │   ├── gnome.nix        # GNOME extensions
    │   └── hyprland.nix     # Hyprland config
    ├── editors/
    │   └── helix.nix        # Helix editor
    └── shell/
        ├── bash.nix         # Shell aliases
        ├── git.nix          # Git config
        ├── ssh.nix          # SSH client
        └── starship.nix     # Prompt
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

### Test in VM

```bash
nixos-rebuild build-vm --flake .#nixos
./result/bin/run-nixos-vm
```

## Desktop

- **Compositor**: Hyprland (Wayland)
- **Shell**: DankMaterialShell (bar, launcher, notifications)
- **Fallback**: GNOME (select from GDM)

### Hyprland Keybinds

| Keys | Action |
|------|--------|
| `Super+Return` | Terminal (Ghostty) |
| `Super+D` | App launcher (DMS Spotlight) |
| `Super+B` | Firefox |
| `Super+Q` | Close window |
| `Super+F` | Fullscreen |
| `Super+V` | Toggle floating |
| `Alt+Tab` | Cycle windows |
| `Super+1-9` | Switch workspace |
| `Super+Shift+1-9` | Move window to workspace |
| `Super+H/J/K/L` | Vim-style focus |

## Adding a New Host

1. Create `hosts/newhost/default.nix` and `hardware.nix`
2. Add to `flake.nix`:
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     modules = [ ./hosts/newhost ];
   };
   ```
3. Build: `sudo nixos-rebuild switch --flake .#newhost`
