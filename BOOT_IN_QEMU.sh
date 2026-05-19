#!/bin/bash
# Boot the MemForge USB in QEMU/UEFI on Linux or macOS.
# Requires: qemu-system-x86_64 and OVMF (ovmf package).
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

command -v qemu-system-x86_64 >/dev/null || {
    echo "[ERROR] qemu-system-x86_64 not found."
    echo "  Debian/Ubuntu: sudo apt install qemu-system-x86 ovmf"
    echo "  Arch:          sudo pacman -S qemu-full edk2-ovmf"
    echo "  macOS:         brew install qemu"
    exit 1
}

# Locate OVMF firmware. Override via OVMF=... env var.
if [ -z "$OVMF" ]; then
    for p in /usr/share/OVMF/OVMF_CODE.fd \
             /usr/share/ovmf/OVMF.fd \
             /usr/share/edk2/x64/OVMF_CODE.fd \
             /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
             /opt/homebrew/share/qemu/edk2-x86_64-code.fd \
             /usr/local/share/qemu/edk2-x86_64-code.fd; do
        [ -f "$p" ] && OVMF="$p" && break
    done
fi
[ -f "$OVMF" ] || { echo "[ERROR] OVMF.fd not found. Set OVMF=/path/to/OVMF.fd"; exit 1; }

echo "Booting $SCRIPT_DIR via UEFI/QEMU..."
echo "OVMF: $OVMF"
echo "Tip: Ctrl+Alt+G to release mouse. Close window to exit."
echo ""
exec qemu-system-x86_64 \
    -bios "$OVMF" \
    -drive format=raw,file=fat:rw:"$SCRIPT_DIR" \
    -m 2G -smp 2 -cpu max \
    -net none
