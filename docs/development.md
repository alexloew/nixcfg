# Development environment

## Shell and terminal

The interactive shell stack is:

- Zsh with completion, vi keybindings and fzf history search
- Starship prompt
- Ghostty terminal
- tmux with `Ctrl+\` as the primary prefix
- Git, SSH and GitHub CLI configuration through Home Manager and shared Netflix modules

Useful tmux integrations include Yazi, Lazygit, popup shells and opening captured pane output in Helix. See [`cheatsheet.md`](cheatsheet.md) for keybindings.

## Editor

Helix is the primary editor. Language support includes:

| Language | Services |
|---|---|
| Python | Ruff, basedpyright, harper-ls |
| Rust | rust-analyzer, harper-ls |
| Nix | nil |
| Markdown | marksman, harper-ls |
| YAML | yaml-language-server |
| SQL | sqlfluff |

The configuration lives in `home/editors/helix.nix`.

## Command-line tools

`home/apps/cli.nix` supplies general utilities, including:

- Ripgrep, fzf, jq, tree, wget and unzip
- Yazi and Lazygit
- GCC, Make and pre-commit
- htop, btop, fastfetch and osquery
- PCI and video-device inspection tools
- Atlassian CLI and fallback Vim

Shared Netflix modules provide organization-specific tools such as Newt, Metatron, Weep, Sourcegraph and the Netflix GitHub wrapper.

## Go development

`home/dev/go.nix` installs Go, gopls, golangci-lint, Delve and gotools. It sets:

```text
GOPATH=$HOME/go
GOBIN=$HOME/go/bin
```

`$HOME/go/bin` is added to the session path.

## Herdr

Herdr is installed from its flake in `home/dev/herdr.nix`. A local package patch teaches its process detection to recognize wrapped AI-agent launchers. Review and remove the patch after equivalent behavior lands upstream.

## Distrobox and Podman

Rootless Podman is the container backend. NixOS configures:

- Docker command compatibility through Podman;
- DNS on the default Podman network;
- weekly pruning of dangling layers and build cache older than seven days;
- NVIDIA Container Device Interface generation; and
- `podman-compose`.

Home Manager declares mutable Distrobox environments in `home/dev/distrobox.nix`:

| Name | Image |
|---|---|
| `ubuntu` | `quay.io/toolbx/ubuntu-toolbox:26.04` |
| `fedora` | `registry.fedoraproject.org/fedora-toolbox:45` |
| `arch` | `quay.io/toolbx/arch-toolbox:latest` |

The boxes share `$HOME`, graphical/audio sockets and a read-only `/nix` mount. `nvidia=true` enables CUDA or explicit dGPU offload; the Intel iGPU still drives the desktop.

Create declared boxes:

```bash
distrobox assemble create --all
```

Common commands:

```bash
distrobox list
distrobox enter arch
distrobox rm arch

distrobox create \
  --name tumbleweed \
  --image registry.opensuse.org/opensuse/tumbleweed:latest

distrobox enter arch -- distrobox-export --app gimp
distrobox-host-exec systemctl status
```

Distrobox containers are mutable. Editing `assemble.ini` does not modify an existing container. Recreate deliberately when its base definition changes:

```bash
distrobox assemble create --replace --all
```

This discards and recreates matching containers; preserve any container-local work first.

## Virtual machines

NixOS enables libvirt with QEMU/KVM, UEFI, software TPM support and virt-manager. A oneshot service creates and starts libvirt's default NAT network when missing. Firewall and TCP MSS rules support VM traffic across the workstation VPN.

Launch the GUI:

```bash
virt-manager
```

Create a test VM from an ISO:

```bash
virt-install \
  --name nixos-test \
  --ram 4096 \
  --vcpus 2 \
  --cdrom /path/to/nixos.iso \
  --disk size=20 \
  --boot uefi
```

VM disks and configuration are mutable libvirt state. They are not rebuilt from this repository.

## Adding packages or modules

- Add user CLI/GUI packages under `home/apps/`.
- Add user-session tools under the relevant `home/` subtree.
- Add machine services under `system/`.
- Add host-specific overrides under `hosts/nixos/`.
- Add external sources in `flake.nix` and update only the named lock input where possible.

Follow [`operations.md`](operations.md) for syntax checks, builds and activation. Do not test changes by editing `/etc/nixos`.
