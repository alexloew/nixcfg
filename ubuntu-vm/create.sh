#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${VM_NAME:-ubuntu24.04}"
IMAGE_DIR="/var/lib/libvirt/images"
ISO_PATH="$IMAGE_DIR/${VM_NAME}-installer.iso"
VM_DISK="$IMAGE_DIR/${VM_NAME}.qcow2"
SEED_ISO="$IMAGE_DIR/${VM_NAME}-seed.iso"
DISK_SIZE="${DISK_SIZE:-50G}"
RAM="${RAM:-4096}"
VCPUS="${VCPUS:-2}"
ISO_URL="https://releases.ubuntu.com/noble/ubuntu-24.04.2-desktop-amd64.iso"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if VM already exists
if sudo virsh dominfo "$VM_NAME" &>/dev/null; then
  echo "Error: VM '$VM_NAME' already exists. Run ./destroy.sh first."
  exit 1
fi

echo "==> Downloading Ubuntu 24.04 Server ISO (cached at $ISO_PATH)..."
if [ ! -f "$ISO_PATH" ]; then
  sudo curl -L --progress-bar "$ISO_URL" -o "$ISO_PATH"
else
  echo "    Already cached, skipping download."
fi

echo "==> Creating VM disk ($DISK_SIZE)..."
sudo qemu-img create -f qcow2 "$VM_DISK" "$DISK_SIZE"

echo "==> Building autoinstall seed ISO..."
sudo cloud-localds "$SEED_ISO" \
  "$SCRIPT_DIR/autoinstall/user-data" \
  "$SCRIPT_DIR/autoinstall/meta-data"

echo "==> Installing VM (this will run unattended, check virt-manager for progress)..."
sudo virt-install \
  --name "$VM_NAME" \
  --ram "$RAM" \
  --vcpus "$VCPUS" \
  --disk "$VM_DISK",format=qcow2 \
  --location "$ISO_PATH,kernel=casper/vmlinuz,initrd=casper/initrd" \
  --extra-args "autoinstall ds=nocloud;s=/cidata/ console=ttyS0,115200" \
  --disk "$SEED_ISO",device=cdrom \
  --os-variant ubuntu24.04 \
  --network network=default \
  --graphics spice \
  --boot uefi \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
  --noautoconsole \
  --wait -1

echo ""
echo "==> VM '$VM_NAME' installed and running."
echo "    Open in virt-manager, or SSH (wait ~30s for boot):"
echo "    ssh ubuntu@\$(sudo virsh domifaddr $VM_NAME | awk '/ipv4/{print \$4}' | cut -d/ -f1)"
echo ""
echo "    Verify TPM inside VM: ls /dev/tpm*"
