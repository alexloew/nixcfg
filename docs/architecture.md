# Configuration architecture

## Flake entry point

`flake.nix` defines one host output:

```text
nixosConfigurations.nixos
```

It builds an `x86_64-linux` NixOS system from four layers:

1. `hosts/nixos` imports detected hardware and the system-module tree.
2. Determinate Nix and the FlakeHub CLI are imported from their flakes.
3. Home Manager imports `home/` for the `alexloewenthal` user.
4. Smallstep, Fleet and shared Netflix modules add organization-specific services and tools.

`flake.lock` pins the complete source graph. A root input may bring its own transitive inputs; inspect the whole lock diff after any update.

## Module tree

```text
hosts/nixos/default.nix
├── hosts/nixos/hardware.nix
└── system/default.nix
    ├── boot.nix
    ├── containers.nix
    ├── desktop/
    ├── hardware.nix
    ├── locale.nix
    ├── network.nix
    ├── nix.nix
    ├── nvidia.nix
    ├── tailscale.nix
    ├── tpm.nix
    ├── users.nix
    └── virt.nix

home/default.nix
├── apps/
├── desktop/
├── dev/
├── editors/
└── shell/
```

The `default.nix` files are aggregators. Put a setting in the narrowest module that owns its lifecycle:

- hardware and system services under `system/`;
- user applications and dotfiles under `home/`;
- machine-specific overrides under `hosts/nixos/`; and
- flake source selection and cross-module wiring in `flake.nix`.

## System and Home Manager boundary

NixOS owns machine-wide state:

- bootloader, initrd and encrypted swap;
- NetworkManager, audio, printing and hardware drivers;
- greetd, Niri session support and the greeter;
- Podman, libvirt, Tailscale, TPM and user accounts; and
- system services from Smallstep, Fleet and Netflix modules.

Home Manager owns the user session:

- Niri KDL settings and user services;
- DankMaterialShell settings;
- applications, editor and terminal configuration;
- shell, Git, SSH and tmux configuration; and
- distrobox definitions and user development tools.

`home-manager.useGlobalPkgs = true` makes Home Manager use the same package set as the NixOS host. `specialArgs` and `home-manager.extraSpecialArgs` pass flake inputs and the shared Niri package into modules that need them.

## External inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | Primary NixOS and package set |
| `determinate` | Determinate Nix module |
| `fh` | FlakeHub CLI |
| `home-manager` | User configuration module |
| `dms` | DankMaterialShell package and Home Manager module |
| `dgop` | Legacy standalone monitoring input; currently unused because DMS embeds dgop |
| `nflx-nixcfg` | Shared Netflix tools and service modules |
| `smallstep` | Netflix Smallstep agent integration |
| `fleetdm-nix` | Fleet/Orbit endpoint agent module |
| `herdr` | Terminal workspace manager |

Inputs that declare `inputs.nixpkgs.follows = "nixpkgs"` share the root package set. Independent package sets can add duplicate dependencies and must be reviewed deliberately.

## Desktop ownership

Desktop configuration is split to avoid competing authorities:

| File | Responsibility |
|---|---|
| `system/desktop/niri.nix` | Niri system package and session integration |
| `system/desktop/dms-greeter.nix` | greetd login through the DMS greeter |
| `home/desktop/niri.nix` | Output geometry, named workspaces, window rules, keybindings and lid handler |
| `home/desktop/dms.nix` | Shell settings, bars, theming, idle behavior and DMS user service |
| `home/desktop/displays.nix` | Wallpaper process and startup application launch |
| `system/hardware.nix` | Lid policy and user-service trigger |

DMS-generated Niri fragments supply only layout and selected runtime behavior. Output, binding and window-rule ownership stays in `home/desktop/niri.nix` to avoid duplicate KDL nodes.

See [`desktop.md`](desktop.md) for the active topology and application layout.

## State outside the Nix store

Not all workstation state is declarative:

- application profiles and browser data live under the home directory;
- distrobox containers are mutable Podman state;
- libvirt machines and disks live under libvirt storage;
- Smallstep enrollment and agent state live under `/etc/step-agent` and `/var/lib/step-agent`;
- Fleet/Orbit keeps runtime state outside the configuration source; and
- generated DMS session/plugin files live under the user config/state directories.

A NixOS switch changes the declared software and service definitions. It does not reset these runtime data stores.
