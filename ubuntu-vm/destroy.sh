#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${VM_NAME:-ubuntu24.04}"
IMAGE_DIR="/var/lib/libvirt/images"

echo "==> Destroying VM '$VM_NAME'..."
sudo virsh destroy "$VM_NAME" 2>/dev/null || true
sudo virsh undefine "$VM_NAME" --nvram --remove-all-storage 2>/dev/null || true
sudo rm -f "$IMAGE_DIR/${VM_NAME}.qcow2"
sudo rm -f "$IMAGE_DIR/${VM_NAME}-cidata.iso"

echo "==> Done."
echo "    Base image preserved at $IMAGE_DIR/${VM_NAME}-base.img"
echo "    Run ./create.sh to recreate from scratch."
