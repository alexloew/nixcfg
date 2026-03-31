# ubuntu-vm

Repeatable Ubuntu 24.04 Desktop (minimal) VM lifecycle with TPM 2.0, managed via Nix flake and Ubuntu autoinstall.

## Prerequisites

### Host system

- NixOS with flakes enabled
- `libvirtd` running with `swtpm` enabled:
  ```nix
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  programs.virt-manager.enable = true;
  ```
- User in the `libvirtd` group:
  ```nix
  users.users.<you>.extraGroups = [ "libvirtd" ];
  ```
- Default libvirt network active:
  ```bash
  sudo virsh net-start default
  sudo virsh net-autostart default
  ```

### Tools (provided by `nix develop`)

| Tool | Purpose |
|------|---------|
| `virt-install` | VM provisioning |
| `virsh` | VM lifecycle management |
| `qemu-img` | Disk image creation |
| `cloud-localds` | Build autoinstall seed ISO |

## VM Credentials

| Field | Value |
|-------|-------|
| Hostname | `ncsetest` |
| Username | `test` |
| Password | `test` |

> **Note:** These are intentionally weak credentials for a local test VM. Do not expose this VM to a network you don't control.

## Usage

### Enter the dev shell

```bash
nix develop
```

### Create the VM

```bash
./create.sh
```

This will:
1. Download the Ubuntu 24.04 Desktop ISO (~6GB, cached at `/var/lib/libvirt/images/ubuntu24.04-installer.iso`)
2. Create a 50GB qcow2 disk
3. Build a seed ISO from `autoinstall/user-data`
4. Boot the installer via `virt-install` — fully unattended (~15–20 min)

Once complete, `testuser` auto-logs in to a minimal GNOME session.

### Destroy the VM

```bash
./destroy.sh
```

Removes the VM, its disk, and the seed ISO. The base installer ISO is **preserved** so the next `./create.sh` skips the download.

### Recreate from scratch

```bash
./destroy.sh && ./create.sh
```

## Configuration

### Autoinstall

`autoinstall/user-data` controls the entire install:

- **Identity**: hostname, username, password
- **Source**: `ubuntu-desktop-minimal` (no snap store, no extra apps)
- **Storage**: LVM layout
- **Packages**: `git`, `curl`, `vim` pre-installed
- **Late commands**: GDM auto-login configured for `test` user

To add packages or run post-install commands, edit `late-commands`:

```yaml
late-commands:
  - curtin in-target -- apt-get install -y your-package
  - curtin in-target -- systemctl enable some-service
```

### Environment variables

Override defaults without editing scripts:

```bash
VM_NAME=myvm DISK_SIZE=100G RAM=8192 VCPUS=4 ./create.sh
```

| Variable | Default | Description |
|----------|---------|-------------|
| `VM_NAME` | `ubuntu24.04` | libvirt domain name |
| `DISK_SIZE` | `50G` | VM disk size |
| `RAM` | `4096` | RAM in MB |
| `VCPUS` | `2` | CPU count |

## Verifying TPM

Inside the VM:

```bash
# Check TPM device is present
ls /dev/tpm*
# Expected: /dev/tpm0 and /dev/tpmrm0

# Verify TPM 2.0
cat /sys/class/tpm/tpm0/tpm_version_major
# Expected: 2

# Full capability check (requires tpm2-tools, pre-installed)
tpm2_getcap properties-fixed
```

## Troubleshooting

**Install hangs or doesn't start**
- Confirm the libvirt default network is running: `sudo virsh net-list`
- Check VM console in virt-manager for installer output

**`virt-install` fails with kernel/initrd error**
- The Desktop ISO uses `casper/vmlinuz` and `casper/initrd` — if the ISO URL changes these paths may shift. Verify with: `isoinfo -l -i ubuntu.iso | grep vmlinuz`

**swtpm permission error**
- Ensure `/var/lib/swtpm-localca` is owned by `tss:tss`
- See NixOS config: `systemd.tmpfiles.rules`

**VM already exists error**
- Run `./destroy.sh` before `./create.sh`
