# MemForge2

UEFI memory diagnostic tool for shop / repair use. Boots from USB before any
OS loads, runs 12 stress and pattern tests in parallel on every CPU core,
captures hardware ECC events via MCA registers, and writes a structured
report to the USB stick for offline review.

## What it actually does

- 12 memory tests covering pattern faults, retention, row hammering, address
  decoding, and sustained thermal stress.
- Direct SPD EEPROM read via Intel SMBus — pulls serial number, manufacturing
  date and JEDEC manufacturer ID from each DIMM (info SMBIOS Type 17 does not
  expose).
- MCA (Machine Check Architecture) snapshot before/after the run — surfaces
  ECC errors that pattern tests cannot see by design (silently corrected by
  the iMC).
- Heuristic DRAM coordinate decode (bank-group / bank / row / column) with
  stuck-row and stuck-bank cluster detection.
- HWP + PL1/PL2 lift — actually pushes the CPU to turbo P-state inside UEFI,
  which most memory testers do not do (their tests run at base frequency).
- y-cruncher-style mixed-port Thermal Soak: saturates FMA, shuffle and
  integer ALU ports simultaneously instead of FMA alone.

## Tests

| # | Test | Time | What it catches |
|---|------|------|-----------------|
| 1 | AVX2 Sustained | ~10 s | VRM / IMC sustained-load faults |
| 2 | TRRespass | ~60 s | DDR4/5 Row Hammer (Frigo et al., USENIX Sec 2020) |
| 3 | Cache-Eviction | ~10 s | DRAM bus errors via CLFLUSH |
| 4 | March-C- | ~2 s | 6-phase JEDEC-grade March (van de Goor 1997, 92% coverage) |
| 5 | Thermal Soak | 3 min | Errors that only surface at thermal steady-state |
| 6 | BW Soak | 5 min | Sustained DRAM bandwidth (memtest86+ analog) |
| 7 | March-RAW | ~3 s | Read-after-write dynamic coupling faults |
| 8 | Butterfly | ~5 s | Cell crosstalk via checkerboard + neighbour flip |
| 9 | Address Pattern | ~5 s | Address-line faults (cell X reads value of Y) |
| 10 | VRM Square-Wave | ~10 s | VRM transient response under 10 Hz load square |
| 11 | Random Pattern | ~6 s | xorshift64 pseudo-random patterns × 4 |
| 12 | Bit Fade Extended | ~8 min | DRAM retention (write → wait → verify, 2 patterns) |

## Strengths vs other tools

- **TRRespass** — 8-sided Row Hammer with bank rotation. Bypasses TRR/RFM
  that the naive 2-aggressor Row Hammer in memtest86+ gets defeated by.
  Reference: Frigo et al., *TRRespass: Exploiting the Many Sides of Target
  Row Refresh*, USENIX Security 2020.
- **March-C-** — formal industrial March algorithm. Most consumer testers
  still use walking-1s/0s from the 1980s.
- **MCA capture** — reads `MCi_STATUS` MSRs before and after the test, diffs
  to surface ECC corrections that pattern tests by design cannot see.
- **SPD via SMBus** — direct ICH/PCH SMBus EEPROM read (serial number,
  manufacturing date, JEDEC bank/code, primary CAS latency).
- **HWP + PL1/PL2 lift** — programs `IA32_HWP_REQUEST` and lifts package
  power limits so the CPU actually runs at turbo during the stress kernels.
  PassMark explicitly admit on their own forum that their tool does not do
  this.
- **Error localization** — 5 mechanisms:
  1. DIMM name via SMBIOS Type 20 (physical address → DIMM slot)
  2. Stuck-bit detection via XOR-mask repetition
  3. Stuck-row detection via DRAM-coord heuristic
  4. Stuck-bank detection via DRAM-coord heuristic
  5. 1-GB histogram of error addresses
- **DDR5-aware** — auto-tunes Bit Fade for on-die ECC, applies 2× multiplier
  to Row Hammer activations to compensate for TRR/RFM.

## Output

After the test, on the USB next to `loader.efi`:

- `memforge2.log` — full run log with timestamps, per-test results, MCA
  bank diffs, per-error records.
- `report.json` — structured data including SPD per DIMM, MCA bank state,
  per-error DRAM coordinates, stuck-row / stuck-bank verdicts, error
  histogram. Plain JSON, easy to feed into any downstream tool.

## Building

Requires MSYS2 + mingw-w64 GCC + gnu-efi headers/library.

```bash
make
```

Produces `MemForge2.efi`. Copy onto a FAT-formatted USB at
`EFI/BOOT/loader.efi`, along with `quantai.ini` at root. Wrap with the
Linux Foundation's `PreLoader.efi` if you want to keep Secure Boot enabled
(MOK enrollment via `HashTool.efi`).

## Configuration

`quantai.ini` on the USB root holds runtime knobs:

```ini
[Run]
Passes=0            ; 0 = auto from RAM size / BufferMB
MultiPass=1         ; rotate buffer across regions to cover all RAM
MaxCores=0          ; 0 = use all enabled cores
EnableAVX=1
;BufferMB=1024      ; auto-scaled by RAM size if commented out
;BitFadeSeconds=60  ; DDR4 default; DDR5 auto-bumped to 120
;BitFadeEveryPass=0 ; only on pass 1 by default

[Meta]
Version=4.6
Language=ru         ; "ru" or "en"

[Display]
;EnableAA=0         ; 1 = AA via direct framebuffer (faster, less compatible)
;ForceBlt=0         ; 1 = always use GOP Blt (slower, max compatibility)
;Width=1920         ; manual GOP mode override
;Height=1080
;FontScale=0        ; 0=auto, 1=1×, 2=2× (for 4K displays)

```

The `[AI]` section that may appear in your local `quantai.ini` is consumed
by an external post-test analyzer (not part of this repo) and is ignored by
the tester itself.

## License

See `LICENSE`.

## Acknowledgements

- Frigo, Giuffrida, Bos, Razavi — TRRespass attack (USENIX Sec 2020)
- A. J. van de Goor — March-C- algorithm (1997)
- Linux Foundation — `PreLoader.efi` / `HashTool.efi` Secure Boot shims
- gnu-efi project — UEFI headers and library
