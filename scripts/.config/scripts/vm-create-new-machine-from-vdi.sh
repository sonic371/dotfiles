#!/usr/bin/env bash
# vm-create-new-machine-from-vdi.sh - Create a VirtualBox VM from a VDI template.
# If a VM or folder with that name already exists, asks before deleting it.

set -e

VM_NAME="${1:-}"
TEMPLATE="${2:-}"
VM_DIR="${HOME}/VirtualBox VMs"
VM_PATH="$VM_DIR/$VM_NAME"

# Validate inputs
[[ -z "$VM_NAME" || -z "$TEMPLATE" ]] && {
    echo "Usage: $0 <vm-name> <template.vdi>" >&2
    exit 1
}

# The name becomes a folder under "VirtualBox VMs" that may be deleted below, so keep it a plain name
[[ "$VM_NAME" == */* || "$VM_NAME" == "." || "$VM_NAME" == ".." ]] && {
    echo "Error: VM name must be a plain name (no '/', not '.' or '..'): $VM_NAME" >&2
    exit 1
}

[[ ! -f "$TEMPLATE" ]] && {
    echo "Error: Template not found: $TEMPLATE" >&2
    exit 1
}

# An existing VM or folder with this name gets deleted for good, so ask first
vm_exists=0; dir_exists=0
VBoxManage showvminfo "$VM_NAME" &>/dev/null && vm_exists=1
[[ -d "$VM_PATH" ]] && dir_exists=1
if (( vm_exists || dir_exists )); then
    (( vm_exists ))  && echo "VM '$VM_NAME' already exists (it and its disks will be deleted)." >&2
    (( dir_exists )) && echo "Folder already exists: $VM_PATH (it will be deleted)." >&2
    read -rp "Delete and recreate '$VM_NAME'? This cannot be undone. [y/N] " ans
    [[ $ans == [yY] ]] || { echo "Cancelled, nothing changed." >&2; exit 1; }
fi

# Clean up any existing VM with same name
if (( vm_exists )); then
    echo "Unregistering and deleting VM '$VM_NAME'..." >&2
    VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
fi

# Remove any leftover directory
if [[ -d "$VM_PATH" ]]; then
    echo "Removing folder: $VM_PATH" >&2
    rm -rf "$VM_PATH"
fi

# Create VM directory
mkdir -p "$VM_PATH"
NEW_VDI="$VM_PATH/$VM_NAME.vdi"

echo "Creating VM '$VM_NAME'..."
echo "Template: $TEMPLATE"
echo "Location: $VM_PATH"

# Clone template
VBoxManage clonemedium disk "$TEMPLATE" "$NEW_VDI" --format VDI

# Create VM
VBoxManage createvm --name "$VM_NAME" --ostype "Other_Linux64" --basefolder "$VM_DIR" --register
VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --bootable on
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$NEW_VDI"
VBoxManage modifyvm "$VM_NAME" --memory 4096 --cpus 2 --nic1 nat

echo "VM created successfully: $VM_PATH"
echo "Start: VBoxManage startvm '$VM_NAME'"
