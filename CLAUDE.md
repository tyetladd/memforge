# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

MemForge2 is a bootable UEFI application (x86_64 only) that stress-tests RAM before any OS loads. It runs 14 parallel memory tests across all CPU cores, reads SPD/SMBIOS hardware info directly, captures MCA (Machine Check Architecture) register snapshots for ECC errors, and writes structured logs to the USB stick. It is a single-file C project targeting the UEFI firmware environment — no OS, no libc.

This project is AI-assisted: Claude writes the C/UEFI code; the repository owner provides domain expertise and validates on real hardware.

## Build

**Requires Windows + MSYS2 + mingw-w64 + gnu-efi headers/library.** The Makefile hardcodes GCC at `/c/msys64/mingw64/bin/gcc.exe` and gnu-efi at `/c/msys64/usr/{include,lib}/efi`.

```bash
make            # produces MemForge2.efi
make clean
```

If Windows Defender Smart App Control blocks GCC, run `WHITELIST_MSYS2.bat` once as Administrator.

### Building on macOS / Linux (Docker)

`Makefile.linux` uses the standard ELF+`objcopy` gnu-efi pipeline. Requires the gold linker because Ubuntu 22.04's BFD linker rejects the PC32 relocation in `crt0-efi-x86_64.o`.

```bash
# OrbStack users must set DOCKER_HOST:
export DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock

docker run --rm -v "$PWD:/work" -w /work ubuntu:22.04 bash -c "
  apt-get update -q && apt-get install -y -q gcc make binutils binutils-gold gnu-efi &&
  make -f Makefile.linux
"
```

Produces `MemForge2.efi` (≈ 314 KB) in the project directory.

There are no unit tests — the only way to test is to boot the EFI binary on real hardware.

## Deployment

1. Format a USB drive as FAT32.
2. Copy `MemForge2.efi` to `EFI/BOOT/loader.efi` on the USB.
3. Copy `quantai.ini` to the USB root.
4. For Secure Boot: also copy `PreLoader.efi` as `EFI/BOOT/BOOTX64.EFI` and `HashTool.efi` alongside it. On first boot, enroll the hash of `loader.efi` via HashTool, then reboot.

## Architecture

### Single-file structure

All ~9 000 lines of application code live in `MemForge2.src.c`. There is intentionally no split into multiple translation units — the UEFI freestanding build environment makes linking complex, and a single file avoids cross-TU linkage headaches.

The file is logically partitioned (in order) into:
- Hardware detection: CPUID flags, RDMSR/WRMSR inline helpers, RAPL energy sampling, HWP/CPPC2 performance-state programming
- SMBIOS parsing: Type 17 (DIMMs) and Type 20 (physical address → DIMM slot map) — populates `g_dimms[]` and `g_dimm_map[]`
- SMBus SPD reads: direct ICH/FCH SMBus EEPROM access for serial numbers, JEDEC IDs, and primary timings not exposed by SMBIOS
- MCA snapshot: `MCi_STATUS` MSR reads before/after run to surface silently-corrected ECC events
- Test kernels (14 tests): each kernel runs on all AP cores via EFI MP Services Protocol
- Display/UI: GOP framebuffer rendering using the embedded bitmap font, progress bars, real-time per-core metrics
- INI parser: reads `quantai.ini` from USB root at startup
- NVRAM persistence: cold/warm boot delta via UEFI `SetVariable`/`GetVariable`
- Log/JSON writer: `memforge2.log` and `report.json` written to the USB partition

### Key globals

- `g_dimms[MAX_DIMMS]` / `g_dimm_map[MAX_DIMM_MAP]` — hardware topology discovered at boot
- `g_aborted` — volatile flag polled by AP kernels; set when user presses ESC/Q on BSP
- Per-test result structures accumulate errors; each error record carries `{t_ms, temp_c, pkg_w, throttle, vid_mv}` environmental snapshot

### Font pipeline

`font_data.h` is **auto-generated** — do not edit it by hand. To regenerate (Windows only, requires Pillow and Consolas):

```bash
python gen_font.py
```

This renders 14×28 px anti-aliased grayscale glyphs for ASCII, Cyrillic, box-drawing, and UI symbols from `C:/Windows/Fonts/consola.ttf` and writes the `UINT8 g_font_glyphs[N][28][14]` array plus a codepoint→index lookup table.

### Two separate systems

The UEFI binary (this repo) is offline — it makes zero network calls. The **AI analyzer** (not in this repo) is a separate Python tool that reads `memforge2.log` / `report.json` from the USB and submits them to Gemini. The `[AI]` section in `quantai.ini` is consumed by that external tool and ignored by the UEFI binary.

## Configuration reference (`quantai.ini`)

Runtime knobs read by the UEFI binary from the USB root:

| Key | Default | Effect |
|-----|---------|--------|
| `Passes` | 0 (auto) | Hard cap on pass count; 0 = derived from RAM/BufferMB |
| `MultiPass` | 1 | Rotate buffer across all RAM regions (full coverage) |
| `MaxCores` | 0 (all) | Cap active CPU cores |
| `EnableAVX` | 1 | Allow AVX2 stress kernel |
| `BufferMB` | auto | Per-allocation size; auto-scaled by RAM size if unset |
| `BitFadeSeconds` | 60/120 | Wait time per Bit Fade phase; DDR5 auto-bumped to 120 |
| `TestOnlyDimm` | 0 | Isolate test buffer to one DIMM slot (1-based) |
| `MarathonHours` | 0 | Run continuously for N hours (1-24) |
| `Language` | en | `en` or `ru` |

## Key constraints

- **Freestanding environment**: no libc, no OS syscalls. Only UEFI Boot Services / Runtime Services and the EFI MP Services Protocol are available.
- **Single BSP + APs**: the boot processor (BSP) runs the UI loop; application processors (APs) run test kernels via `EFI_MP_SERVICES_PROTOCOL.StartupAllAPs`. The `g_aborted` volatile flag is the only synchronisation primitive between BSP and APs.
- **DDR5 quirk**: on-die ECC silently corrects 1-bit errors within each chip, so a PASS result on DDR5 means "no errors that ODECC couldn't fix" — not "cells are perfect". The binary auto-doubles Row Hammer activations and extends Bit Fade to 120 s on DDR5 systems to compensate.
- **XMP/EXPO**: overclocked profiles can produce false positives. Always retest at JEDEC defaults before concluding a DIMM is defective.
- **ECC servers**: silently-corrected single-bit errors won't appear in pattern test results — only the MCA snapshot reveals them.
