#!/usr/bin/env bash
# write_usb.sh — prepare a MemForge boot USB on macOS or Linux.
#
# Creates the correct UEFI directory layout on the target drive:
#   EFI/BOOT/BOOTX64.EFI  ← PreLoader.efi  (if present, enables Secure Boot)
#   EFI/BOOT/HashTool.efi ← (if present)
#   EFI/BOOT/loader.efi   ← MemForge2.efi
#   quantai.ini            ← runtime config

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EFI_BIN="$SCRIPT_DIR/MemForge2.efi"
INI="$SCRIPT_DIR/quantai.ini"

# ── colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; NC='\033[0m'
die() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
info() { echo -e "${GRN}[+]${NC} $*"; }
warn() { echo -e "${YEL}[!]${NC} $*"; }

# ── pre-flight ────────────────────────────────────────────────────────────────
[[ -f "$EFI_BIN" ]] || die "MemForge2.efi not found. Build first:
  macOS/Linux: docker run ... make -f Makefile.linux
  Windows:     make"

[[ -f "$INI" ]] || die "quantai.ini not found in $SCRIPT_DIR"

# Optional Secure Boot shims (place next to this script to include them)
PRELOADER="$SCRIPT_DIR/PreLoader.efi"
HASHTOOL="$SCRIPT_DIR/HashTool.efi"

echo "======================================================"
echo "  MemForge USB writer"
echo "  Source: $SCRIPT_DIR"
echo "======================================================"
echo

# ── detect OS and list candidate drives ───────────────────────────────────────
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    info "External disks:"
    diskutil list external physical 2>/dev/null || diskutil list | grep -v 'internal'
    echo
    read -rp "Enter disk identifier (e.g. disk2, NOT a partition like disk2s1): " DISK
    DISK="${DISK#/dev/}"   # strip /dev/ if user typed it
    [[ -n "$DISK" ]] || die "No disk entered."
    DEV="/dev/$DISK"
    [[ -b "$DEV" ]] || die "$DEV not found."
    # Must be external
    diskutil info "$DEV" | grep -qi "removable\|external" \
        || die "$DEV does not appear to be a removable/external drive. Aborting."
    DISK_INFO="$(diskutil info "$DEV" | grep -E 'Device|Size|Content')"

elif [[ "$OS" == "Linux" ]]; then
    info "Block devices (removable flag = 1 means USB):"
    lsblk -d -o NAME,SIZE,TRAN,RM,MODEL | grep -v "^loop"
    echo
    read -rp "Enter device (e.g. sdb, NOT a partition like sdb1): " DISK
    DISK="${DISK#/dev/}"
    [[ -n "$DISK" ]] || die "No device entered."
    DEV="/dev/$DISK"
    [[ -b "$DEV" ]] || die "$DEV not found."
    RM="$(cat /sys/block/$DISK/removable 2>/dev/null || echo 0)"
    [[ "$RM" == "1" ]] || { warn "$DEV removable flag is 0 — are you sure this is a USB drive?"; }
    DISK_INFO="$(lsblk -o NAME,SIZE,TRAN,MODEL "$DEV" 2>/dev/null || true)"

else
    die "Unsupported OS: $OS"
fi

# ── confirmation ───────────────────────────────────────────────────────────────
echo
echo "------------------------------------------------------"
warn "ABOUT TO ERASE: $DEV"
echo "$DISK_INFO"
echo "------------------------------------------------------"
read -rp "Type YES to format $DEV as FAT32 and write MemForge: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || die "Confirmation not given. Aborting."

# ── format ─────────────────────────────────────────────────────────────────────
info "[1/3] Formatting $DEV as FAT32 (label MEMFORGE)..."
if [[ "$OS" == "Darwin" ]]; then
    diskutil eraseDisk FAT32 MEMFORGE MBRFormat "$DEV"
    MOUNT="/Volumes/MEMFORGE"
    # Wait for automount
    for i in $(seq 1 10); do [[ -d "$MOUNT" ]] && break; sleep 1; done
    [[ -d "$MOUNT" ]] || die "Volume didn't mount at $MOUNT after format."
else
    # Unmount any existing partitions on the device
    umount "${DEV}"* 2>/dev/null || true
    mkfs.fat -F32 -n MEMFORGE "$DEV"
    MOUNT="/mnt/memforge_usb"
    mkdir -p "$MOUNT"
    mount "$DEV" "$MOUNT"
fi

# ── copy files ─────────────────────────────────────────────────────────────────
info "[2/3] Creating EFI directory layout..."
mkdir -p "$MOUNT/EFI/BOOT"

cp "$EFI_BIN" "$MOUNT/EFI/BOOT/loader.efi"

if [[ -f "$PRELOADER" ]]; then
    cp "$PRELOADER" "$MOUNT/EFI/BOOT/BOOTX64.EFI"
    info "  PreLoader.efi included → Secure Boot stays enabled"
    [[ -f "$HASHTOOL" ]] && cp "$HASHTOOL" "$MOUNT/EFI/BOOT/HashTool.efi"
else
    # No PreLoader: make MemForge itself the default boot entry
    cp "$EFI_BIN" "$MOUNT/EFI/BOOT/BOOTX64.EFI"
    warn "  PreLoader.efi not found — copied MemForge2.efi as BOOTX64.EFI"
    warn "  Secure Boot must be disabled on target machine."
    warn "  To enable Secure Boot support, place PreLoader.efi + HashTool.efi"
    warn "  next to this script and re-run."
fi

cp "$INI" "$MOUNT/"

info "[3/3] Flushing..."
if [[ "$OS" == "Darwin" ]]; then
    diskutil eject "$DEV"
else
    umount "$MOUNT"
    rmdir "$MOUNT"
fi

echo
echo "======================================================"
info "DONE. USB is ready."
echo "  Boot order:  EFI/BOOT/BOOTX64.EFI → loader.efi"
echo "  Config:      quantai.ini (edit before booting if needed)"
echo "  BIOS setup:  see BIOS_SETUP.md"
echo "======================================================"
