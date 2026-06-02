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
- [ ] Replace current LED logic with new color code:
  - Blue blinking: relay ON + BLE connected
  - Blue solid: relay ON + BLE disconnected
  - Green blinking: relay OFF + BLE connected
  - Green solid: relay OFF + BLE disconnected
- [ ] Extract LED logic into `led/led.h` module with clear states
- [ ] Ceedling unit tests for LED state transitions
- **Acceptance**: LED reflects relay state and BLE connection independently

### 🔄 Cross-validation
- **Micro validates App**: Visual LED matches app state indicator
- **App validates Micro**: Toggle relay → LED color changes; disconnect → LED stops blinking

---

## Sprint 7: Relay Timer (Core Logic)

### Micro: Auto-Off Timer
- [ ] New module `timer/relay_timer.{c,h}` with HAL for testability
- [ ] Add BLE characteristic: Timer Duration (Write, uint16, seconds, max 21600 = 6h)
- [ ] On relay ON with timer=0 (indefinite): start internal 10-minute max timer
- [ ] On relay ON with timer>0: start countdown of the specified duration (capped at 6h)
- [ ] On timer expiry → `relay_off()` + send Notify
- [ ] Cancel timer on manual relay OFF or new timer write
- [ ] Add BLE characteristic: Timer Remaining (Read + Notify, uint16, seconds)
- [ ] Ceedling unit tests for timer logic (expiry, cancel, cap, indefinite default)
- **Acceptance**: Relay auto-off after configured time; indefinite ON limited to 10 min

### 🔄 Cross-validation
- **Micro validates App**: App sets 60s timer → relay OFF at 60s ✓
- **App validates Micro**: Timer remaining decrements; notify fires on expiry

---

## Sprint 8: Autonomous Operation (No BLE Required)

### Micro: Standalone Behavior After Disconnect
- [ ] Remove old 30s disconnect-timeout fail-safe (safety module)
- [ ] On BLE disconnect: relay keeps current state + timer continues running
- [ ] Timer expiry works identically whether BLE is connected or not
- [ ] On reconnect: app can read current state and remaining timer
- [ ] Watchdog still active (15s, feed in main loop) for firmware hang protection
- [ ] Ceedling unit tests: disconnect mid-timer → timer still expires → relay OFF
- **Acceptance**: Device operates correctly without BLE; app is optional after programming

### 🔄 Cross-validation
- **Micro validates App**: Set 2-min timer → disconnect → wait 2 min → reconnect → state is OFF
- **App validates Micro**: Reconnect after timer expired → reads OFF; reconnect before → reads ON + remaining time
- **Stress test**: Set timer → kill app → relay OFF at correct time

---

## Sprint 9: Fail-Safe (Revised)

### Micro: Watchdog + Exception Safety
- [ ] Watchdog (15s) remains: firmware hang → reset → relay OFF at boot
- [ ] Startup state: relay always OFF regardless of previous state
- [ ] GPIO configured LOW before any initialization (hardware fail-safe)
- [ ] No NVS persistence of relay state (always cold-start OFF)
- [ ] Ceedling tests for init-always-OFF behavior
- **Acceptance**: Any unexpected reset/exception → relay is OFF

### 🔄 Cross-validation
- **Stress test**: Power cycle during ON → relay OFF on reboot

---

## Sprint 10: Power Optimization

### Micro: Low Power
- [ ] Enable Zephyr idle thread (automatic sleep between events)
- [ ] Configure BLE connection intervals (100–500ms)
- [ ] Reduce advertising power when no connection for >60s
- [ ] Measure current consumption (target: < 5mA idle connected, < 1mA advertising)
- **Acceptance**: Measured current acceptable for car battery (months of standby)
- **Validates with App**: Connection remains stable with longer intervals

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


