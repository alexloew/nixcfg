# nixcfg

Personal NixOS configuration for the `nixos` workstation. The flake combines NixOS system modules, Home Manager configuration and selected external flakes into one reproducible host configuration.

## Source of truth

The authoritative flake is:

```text
/home/alexloewenthal/gh-personal/nixcfg
```

Do not build, update or activate `/etc/nixos`. Run every command against this checkout explicitly.

## Common operations

```bash
# Build without activating
nh os build /home/alexloewenthal/gh-personal/nixcfg#nixos

# Temporarily activate until reboot
nh os test /home/alexloewenthal/gh-personal/nixcfg#nixos

# Activate and make the generation the boot default
nh os switch /home/alexloewenthal/gh-personal/nixcfg#nixos
```

`test` and `switch` change the running system. Review the diff and build successfully before using either command.

## Documentation

| Guide | Contents |
|---|---|
| [`docs/operations.md`](docs/operations.md) | Safe builds, activation, input updates, rollback and garbage collection |
| [`docs/architecture.md`](docs/architecture.md) | Flake structure, module boundaries, inputs and ownership |
| [`docs/desktop.md`](docs/desktop.md) | Niri, DMS, displays, named workspaces, startup apps and lid behavior |
| [`docs/development.md`](docs/development.md) | Shell, editor, containers, Go tools and virtualization |
| [`docs/cheatsheet.md`](docs/cheatsheet.md) | Niri screenshots, tmux and Helix keybindings |

## Repository map

```text
flake.nix             Flake inputs and nixosConfigurations.nixos
flake.lock            Pinned input graph
hosts/nixos/          Host entry point and detected hardware
system/               NixOS modules and services
home/                 Home Manager modules
  apps/               User applications
  desktop/            Niri, DMS, displays and fonts
  dev/                Development environments
  editors/            Editor configuration
  shell/              Shell, Git, SSH and tmux
docs/                 Operator and contributor guides
```

Start with [`docs/operations.md`](docs/operations.md) before updating inputs or activating a generation.
