# Firmware — XIAO Remote Button

BLE-controlled relay firmware for **Seeed XIAO nRF52840 Sense** using nRF Connect SDK v2.9.

## Prerequisites

- nRF Connect SDK v2.9 installed at `~/ncs`
- ARM GCC toolchain (`arm-none-eabi-gcc`)
- `west` build tool
- Ceedling (for unit tests): `gem install ceedling`

## Build

```bash
cd micro
ZEPHYR_TOOLCHAIN_VARIANT=cross-compile \
CROSS_COMPILE=/usr/bin/arm-none-eabi- \
ZEPHYR_BASE=~/ncs/zephyr \
  west build -b xiao_ble/nrf52840/sense --no-sysbuild .
```

> **Important**: `--no-sysbuild` is mandatory to produce the correct UF2 at start address `0x27000`.

## Flash

1. Double-tap RESET on the XIAO to enter UF2 bootloader (appears as `XIAO-SENSE` USB drive)
2. Copy the UF2 file:
   ```bash
   cp build/zephyr/zephyr.uf2 /media/$USER/XIAO-SENSE/
   sync
   ```
3. Device reboots automatically

## Run Tests

```bash
cd micro
ceedling test:all       # Run all unit tests
ceedling gcov:all       # Generate coverage report
```

Coverage report: `build/test/artifacts/gcov/gcovr/coverage.txt`

## Module Architecture

| Module | Purpose |
|--------|---------|
| `ble/` | GATT service (5 characteristics), advertising, connection callbacks |
| `relay/` | Dual-pin GPIO relay control (P0.02 + P0.10) with state callback |
| `led/` | RGB LED status code (4 states + error) |
| `timer/` | Pure-logic countdown timer (tick-based, 1Hz) |
| `watchdog/` | 15s hardware watchdog (fail-safe reset) |

## BLE GATT Service

UUID: `00001523-1212-efde-1523-785feabcd123`

| Characteristic | UUID suffix | Properties | Description |
|----------------|-------------|-----------|-------------|
| Relay Command | `1524` | Write | `0x01`=ON, `0x00`=OFF |
| Relay State | `1525` | Read, Notify | Current state byte |
| Timer Duration | `1526` | Write | uint16 LE (seconds, 0=10min default) |
| Timer Remaining | `1527` | Read, Notify | uint16 LE (seconds) |
| Uptime | `1528` | Read | uint32 LE (seconds since boot) |

## Power Configuration

- `CONFIG_PM=y` — Zephyr idle sleep between events
- Connection intervals: 100–500ms, slave latency 4
- Advertising: 100–150ms (fast discovery)
- Supervision timeout: 10s

## Serial Console (Debug)

```bash
# After boot, serial appears at /dev/ttyACM0
cat /dev/ttyACM0
```

Logs use Zephyr logging (`LOG_INF`, `LOG_WRN`, `LOG_ERR`).
