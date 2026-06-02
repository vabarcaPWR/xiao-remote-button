# Firmware Roadmap — xiao-remote-button

> ⚠️ This roadmap is developed in parallel with `roadmap.app.md`.
> Each sprint delivers a complete feature validated end-to-end:
> the firmware is validated with the app and the app is validated with the firmware.
> See the integrated sprint table below.

---

## Sprint 1: Setup & Blink (Independent)

### Micro: Project Setup
- [x] Initialize nRF Connect SDK project with CMake + west
- [x] Configure `prj.conf` for XIAO nRF52840 (BLE, GPIO, logging)
- [x] Create board overlay for `xiao_ble_nrf52840`
- [x] Verify build + flash pipeline works
- [x] Ceedling test: placeholder passes
- **Acceptance**: `west build` succeeds, firmware runs on device, logs via USB console
- **Validates with App**: N/A (independent)

---

## Sprint 2: BLE Advertising + Scanner

### Micro: BLE Advertising
- [x] Enable BLE peripheral role
- [x] Configure advertising with device name "xiao-relay"
- [x] Include custom service UUID in advertising data
- [x] Advertising auto-restarts on disconnect
- **Acceptance**: Device visible in BLE scan with name "xiao-relay"

### 🔄 Cross-validation ✅
- [x] **Micro validates App**: App scanner finds "xiao-relay" by UUID filter
- [x] **App validates Micro**: App detects device → advertising works correctly
- **Issues found & fixed**:
  - Board target: `xiao_ble/nrf52840/sense` (not plain `nrf52840`)
  - NCS Partition Manager links code at 0x0 instead of 0x27000: fix with `--no-sysbuild` + `CONFIG_PARTITION_MANAGER_ENABLED=n`

---

## Sprint 3: BLE Connection + Pairing

### Micro: GATT Service Shell + Pairing
- [x] Register custom GATT service (stub characteristics for cmd/state)
- [x] Implement Just Works pairing (no PIN required)
- [x] Handle GAP connect/disconnect events with logging
- [x] Track connection handle
- [x] Re-advertise on disconnect
- [x] LED status indication: slow blink red = advertising, solid green = connected, fast red = error
- **Acceptance**: App connects directly (no PIN dialog), firmware logs connection, LED reflects state

### 🔄 Cross-validation ✅
- [x] **Micro validates App**: App must connect and discover GATT service without PIN prompt
- [x] **App validates Micro**: If connection fails or drops → firmware config is wrong

---

## Sprint 4: Relay Control via BLE

### Micro: Relay GPIO + Write Characteristic
- [x] Configure P0.02 (D0) as GPIO output, default LOW
- [x] Implement `relay_init()`, `relay_on()`, `relay_off()`, `relay_get_state()`
- [x] Implement Write characteristic (0x01=ON, 0x00=OFF) → calls relay functions
- [x] Implement Read characteristic (returns current state)
- [x] Ceedling unit tests for relay logic (on, off, get_state, init defaults OFF)
- **Acceptance**: Writing 0x01 activates relay GPIO, writing 0x00 deactivates

### 🔄 Cross-validation ✅
- [x] **Micro validates App**: App toggle button must physically switch relay
- [x] **App validates Micro**: If relay doesn't respond to writes → firmware GATT handler is wrong
- [x] **Physical check**: Multimeter on P0.02 confirms voltage change

---

## Sprint 5: State Notifications

### Micro: Notify Characteristic
- [x] Implement Notify characteristic (push on every state transition)
- [x] Send notification when relay state changes (from Write or from timer)
- [x] Handle subscribe/unsubscribe to CCC descriptor
- **Acceptance**: App receives real-time state updates without polling

### 🔄 Cross-validation
- **Micro validates App**: App state indicator must update immediately on toggle
- **App validates Micro**: If app shows stale state → firmware notify is broken

---

## Sprint 6: LED Status Code

### Micro: LED State Machine
- [x] Replace current LED logic with new color code:
  - Blue blinking: relay ON + BLE connected
  - Blue solid: relay ON + BLE disconnected
  - Green blinking: relay OFF + BLE connected
  - Green solid: relay OFF + BLE disconnected
- [x] Extract LED logic into `led/led.h` module with clear states
- [x] Ceedling unit tests for LED state transitions (11 tests)
- **Acceptance**: LED reflects relay state and BLE connection independently

### 🔄 Cross-validation ✅
- [x] **Micro validates App**: Visual LED matches app state indicator
- [x] **App validates Micro**: Toggle relay → LED color changes; disconnect → LED stops blinking
- **Note**: Azul sólido (ON+disconnected) no observable porque safety module (Sprint 8) apaga relay a los 30s — correcto para estado actual

---

## Sprint 7: Relay Timer (Core Logic)

### Micro: Auto-Off Timer
- [x] New module `timer/relay_timer.{c,h}` with HAL for testability
- [x] Add BLE characteristic: Timer Duration (Write, uint16, seconds, max 21600 = 6h)
- [x] On relay ON with timer=0 (indefinite): start internal 10-minute max timer
- [x] On relay ON with timer>0: start countdown of the specified duration (capped at 6h)
- [x] On timer expiry → `relay_off()` + send Notify
- [x] Cancel timer on manual relay OFF or new timer write
- [x] Add BLE characteristic: Timer Remaining (Read + Notify, uint16, seconds)
- [x] Ceedling unit tests for timer logic (expiry, cancel, cap, indefinite default) — 13 tests
- **Acceptance**: Relay auto-off after configured time; indefinite ON limited to 10 min

### 🔄 Cross-validation ✅
- [x] **Micro validates App**: App sets 60s timer → relay OFF at 60s ✓
- [x] **App validates Micro**: Timer remaining decrements; notify fires on expiry ✓
- **Bug found & fixed**: bt_gatt_notify used attrs[10] (CCC) instead of attrs[9] (Char Value)

---

## Sprint 8: Autonomous Operation (No BLE Required)

### Micro: Standalone Behavior After Disconnect
- [x] Remove old 30s disconnect-timeout fail-safe (safety module)
- [x] On BLE disconnect: relay keeps current state + timer continues running
- [x] Timer expiry works identically whether BLE is connected or not
- [x] On reconnect: app can read current state and remaining timer
- [x] Watchdog still active (15s, feed in main loop) for firmware hang protection
- [x] Ceedling unit tests: timer logic independent of BLE (13 timer tests)
- **Acceptance**: Device operates correctly without BLE; app is optional after programming

### 🔄 Cross-validation ✅
- [x] **Micro validates App**: Set 1-min timer → disconnect → wait 1 min → LED goes green (OFF) ✓
- [x] **App validates Micro**: Reconnect after timer expired → reads OFF (confirmed via LED + bluetoothctl)
- [x] **Stress test**: Timer expiry without BLE → relay OFF at correct time ✓
- **Note**: flutter_blue_plus reconnection on Linux/BlueZ has caching issues; full app test deferred to Android

---

## Sprint 9: Fail-Safe (Revised)

### Micro: Watchdog + Exception Safety
- [x] Watchdog (15s) remains: firmware hang → reset → relay OFF at boot
- [x] Startup state: relay always OFF regardless of previous state
- [x] GPIO configured LOW before any initialization (hardware fail-safe)
- [x] No NVS persistence of relay state (always cold-start OFF)
- [x] Added Uptime characteristic (0x1528, Read, uint32 LE, seconds) for reboot detection
- [x] Ceedling tests for init-always-OFF behavior (existing relay tests)
- **Acceptance**: Any unexpected reset/exception → relay is OFF

### 🔄 Cross-validation ✅
- [x] **Stress test**: Power cycle during ON → relay OFF on reboot ✓
- [x] **LED confirms**: Green solid after every reboot ✓

---

## Sprint 10: Power Optimization

### Micro: Low Power
- [x] Enable Zephyr idle thread (CONFIG_PM=y — automatic sleep between events)
- [x] Configure BLE connection intervals (100–500ms, latency 4, timeout 10s)
- [x] Fast advertising (100–150ms) for reliable discovery
- [ ] Measure current consumption (target: < 5mA idle connected, < 1mA advertising)
- **Acceptance**: Connection stable with power-optimized params ✅ (cross-validated)
- **Validates with App**: Connection remains stable with longer intervals ✅

---

## Sprint 11: Production Hardening

### Micro: Stability
- [ ] Full test coverage (80%+)
- [ ] Power consumption profiling and optimization
- [ ] Stress testing (rapid connect/disconnect cycles, 1000+ toggles)
- [ ] Timer accuracy validation (drift < 1% over 6h)
- [ ] Documentation complete
- **Acceptance**: Runs 30 days unattended without issues

### 🔄 Cross-validation
- **App validates Micro**: Automated test: connect → set timer → disconnect → verify timing


