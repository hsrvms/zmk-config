# ZMK Handwired 12×4 Keyboard — Handoff

## Project Overview

Building firmware for a handwired 12×4 ortholinear keyboard (48 keys) using:
- **Controller**: Pro Micro nRF52840 (USB label "NICENANO", board definition `nice_nano`)
- **Layout**: Miryoku QWERTY with VI navigation and home row mods
- **Build method**: Local build (no GitHub Actions)

## Current State

### ✅ Completed
- ZMK build environment set up: `~/zmk-venv`, `~/zephyr-sdk` (v0.17.0), `west`, `cmake`, `dtc` (from SDK)
- West workspace initialized with ZMK v0.3 + miryoku_zmk (master)
- Miryoku source copied into `config/miryoku/` (not a symlink — intentional copy to allow local custom_config.h edits without modifying upstream)
- Shield definition created at `config/boards/shields/handwired_12x4/`
- Keymap using planck 48-key mapping with Miryoku QWERTY + VI nav
- **Firmware compiles successfully**: `zmk/app/build/zephyr/zmk.uf2` (371 KB, 23% flash, 18% RAM)
- Build script at `build.sh` (incremental / clean / flash)
- Git diff ready — old template files deleted, new shield files created

### 🔲 Next Steps (User's Current Task)
User is about to physically wire the matrix to the controller. After wiring:
1. Flash firmware and test matrix scanning
2. Verify each key position registers correctly
3. Test Miryoku layers (home row mods, VI nav, thumb layer activation)
4. Iterate on layout tweaks if needed

## Architecture

### Pin Mapping: GPIO → Controller Silk Labels

**Rows** (4 wires, inputs — `GPIO_ACTIVE_LOW | GPIO_PULL_UP`):

| Row | GPIO | Pro Micro Silk Label |
|-----|------|---------------------|
| 0 | `&gpio0 6` | **D1** |
| 1 | `&gpio0 8` | **D0** |
| 2 | `&gpio0 17` | **D2** |
| 3 | `&gpio0 20` | **D3** |

**Columns** (12 wires, outputs — `GPIO_ACTIVE_LOW`):

| Col | GPIO | Pro Micro Silk Label | Base Key |
|-----|------|---------------------|----------|
| 0 | `&gpio0 22` | **D4** (A6) | Q |
| 1 | `&gpio0 24` | **D5** | W |
| 2 | `&gpio1 0` | **D6** (A7) | E |
| 3 | `&gpio0 11` | **D7** | R |
| 4 | `&gpio1 4` | **D8** (A8) | T |
| 5 | `&gpio1 6` | **D9** (A9) | Y |
| 6 | `&gpio0 9` | **D10** (A10) | U |
| 7 | `&gpio0 10` | **D16** | I |
| 8 | `&gpio1 11` | **D14** | O |
| 9 | `&gpio1 13` | **D15** | P |
| 10 | `&gpio1 15` | **D18** (A0) | { |
| 11 | `&gpio0 2` | **D19** (A1) | } |

### Matrix Configuration
- **Diode direction**: `col2row` — diode anode on column side, cathode (stripe) toward row side
- **12×4 matrix transform**: direct row-major mapping `RC(0,0)` through `RC(3,11)`

### Miryoku Layout
- **`config/miryoku/custom_config.h`**: `MIRYOKU_ALPHAS_QWERTY`, `MIRYOKU_NAV_VI`
- **Home row mods** (Miryoku default): left = A→Super, S→Alt, D→Ctrl, F→Shift; right = mirrored
- **Mapping**: `mapping/48/planck.h` — 3×10 alphas + 3 thumb keys per hand, 12 unused positions
- **10 layers**: Base, Extra, Tap, Button, Nav (VI), Mouse, Media, Num, Sym, Fun

## Key Files

| File | Purpose |
|------|---------|
| `config/west.yml` | West manifest: ZMK v0.3 + miryoku_zmk master |
| `config/handwired_12x4.keymap` | Top-level keymap (includes Miryoku source) |
| `config/miryoku/custom_config.h` | Miryoku layout options (QWERTY + VI nav) |
| `config/boards/shields/handwired_12x4/handwired_12x4.overlay` | Kscan, matrix transform, physical layout |
| `config/boards/shields/handwired_12x4/Kconfig.shield` | Shield name definition |
| `config/boards/shields/handwired_12x4/Kconfig.defconfig` | Keyboard name ("HW12x4") |
| `config/boards/shields/handwired_12x4/handwired_12x4.conf` | Kconfig options (deep sleep commented out) |
| `config/boards/shields/handwired_12x4/handwired_12x4.zmk.yml` | Hardware metadata |
| `config/dts/.gitkeep` | Exists so ZMK adds config/ to DTS include path |
| `zephyr/module.yml` | ZMK module definition (board_root: .) |
| `build.sh` | Build script (build/clean/flash) |

## Build Commands

```bash
cd /home/hsrvms/code/zmk-config
./build.sh          # incremental build
./build.sh clean    # pristine build (required after shield/keymap changes)
./build.sh flash    # shows UF2 copy instructions
```

Or manually:
```bash
source ~/zmk-venv/bin/activate
export PATH="~/zephyr-sdk/sysroots/sysroots/x86_64-pokysdk-linux/usr/bin:$PATH"
cd zmk/app
west build -p -b nice_nano \
  -- -DSHIELD=handwired_12x4 \
  -DZMK_CONFIG=/home/hsrvms/code/zmk-config/config \
  -DZEPHYR_TOOLCHAIN_VARIANT=zephyr \
  -DZEPHYR_SDK_INSTALL_DIR=/home/hsrvms/zephyr-sdk
```

## Flashing
1. Double-click reset on the Pro Micro
2. "NICENANO" USB mass storage device appears
3. `cp zmk/app/build/zephyr/zmk.uf2 /run/media/$USER/NICENANO/`

## Design Decisions

- **Miryoku source is copied, not symlinked**: The `config/miryoku/` directory is a copy of `miryoku_zmk/miryoku/`. This allows editing `custom_config.h` locally without modifying the git submodule. If upstream miryoku_zmk is updated, re-copy the directory.
- **GPIO references use `&gpio0`/`&gpio1` directly** (not `&pro_micro` labels) because the user provided raw GPIO pin numbers. Both work equivalently.
- **`ACTIVE_LOW` for all pins**: User specified this. Columns driven low during scanning; rows pulled up when idle.
- **No `keys` property on physical layout**: ZMK Studio support intentionally omitted (not needed).
- **Old template files deleted**: `build.yaml`, `.github/workflows/`, `boards/shields/test_2x3/` — all removed from the initial repo template.

## Environment

- **OS**: Linux (CachyOS/Arch-based)
- **Python venv**: `~/zmk-venv` (west 1.5.0, Python 3.14.6)
- **Zephyr SDK**: `~/zephyr-sdk` (v0.17.0, ARM toolchain in `arm-zephyr-eabi/bin/`)
- **dtc**: Available from SDK at `~/zephyr-sdk/sysroots/sysroots/x86_64-pokysdk-linux/usr/bin/dtc`
- **gperf**: Not installed (not required for this build)
- **Controller USB**: Shows as "NICENANO" when in bootloader mode (UF2 flashing)

## Git Status

Uncommitted changes (staged for next commit):
- **Deleted**: `.github/workflows/build.yml`, `build.yaml`, `boards/shields/test_2x3/*` (old template)
- **Modified**: `.gitignore`, `config/west.yml`, `zephyr/module.yml`
- **New**: `build.sh`, `config/boards/shields/handwired_12x4/*`, `config/dts/`, `config/handwired_12x4.keymap`, `config/miryoku/` (copied source)

## Suggested Skills

- **piv-loop** — For iterating on layout refinements (e.g., adding a gaming layer, tweaking hold-tap timings, adding combos)
- **code-review** — Before the first commit to review the full diff
- **tdd** — If adding custom ZMK behaviors or non-trivial keymap modifications
