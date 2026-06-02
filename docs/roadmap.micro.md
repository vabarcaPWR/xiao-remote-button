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
- [x] Send notification when relay state changes (from Write or from fail-safe)
- [x] Handle subscribe/unsubscribe to CCC descriptor
- **Acceptance**: App receives real-time state updates without polling

### 🔄 Cross-validation
- **Micro validates App**: App state indicator must update immediately on toggle
- **App validates Micro**: If app shows stale state → firmware notify is broken

---

## Sprint 6: Fail-Safe Mechanisms

### Micro: Disconnect Timeout + Watchdog
- [ ] Implement BLE disconnect callback → start 30s Zephyr timer
- [ ] On timer expiry without reconnection → `relay_off()`
- [ ] On reconnection within 30s → cancel timer, keep state
- [ ] Send Notify on fail-safe trigger (pending for next connection)
- [ ] Configure hardware watchdog (15s timeout), feed in main loop
- [ ] Ceedling unit tests for timeout logic
- **Acceptance**: Relay OFF 30s after disconnect; watchdog reset → relay OFF

### 🔄 Cross-validation
- **Micro validates App**: After app disconnects, relay must turn OFF in 30s
- **App validates Micro**: Reconnect within 30s → relay keeps state; after 30s → relay shows OFF
- **Stress test**: Kill app process → verify relay goes OFF

---

## Sprint 7: Power Optimization

### Micro: Low Power
- [ ] Enable Zephyr idle thread (automatic sleep between events)
- [ ] Configure BLE connection intervals (100–500ms)
- [ ] Reduce advertising interval when connected
- [ ] Measure current consumption (target: < 5mA idle connected)
- **Acceptance**: Measured current acceptable for car battery
- **Validates with App**: Connection remains stable with longer intervals

---

## Sprint 8: Auto-Off Timer

### Micro: Timer Characteristic
- [ ] Add BLE characteristic for timer duration (Write, uint16, minutes)
- [ ] Implement countdown → `relay_off()` when timer expires
- [ ] Send Notify when timer triggers auto-off
- [ ] Cancel timer on manual OFF or new timer write
- [ ] Ceedling tests for timer logic
- **Acceptance**: Relay auto-off after configured minutes

### 🔄 Cross-validation
- **Micro validates App**: App countdown must match actual relay-off moment
- **App validates Micro**: If timer fires early/late → firmware timer is wrong

---

## Sprint 9: Persistent Configuration

### Micro: NVS Storage
- [ ] Store device name in NVS/settings subsystem
- [ ] Store default timer value in NVS
- [ ] Store PIN in NVS (allow change via BLE config characteristic)
- **Acceptance**: Config survives power cycle

### 🔄 Cross-validation
- **App validates Micro**: Change device name via app → reboot device → app sees new name

---

## Sprint 10: Multi-Relay Architecture

### Micro: Extensible Design
- [ ] Refactor relay module to accept relay index parameter
- [ ] Abstract GPIO pin mapping via devicetree
- [ ] Keep single-relay behavior unchanged (index 0)
- **Acceptance**: Architecture supports N relays, current behavior unchanged
- **Validates with App**: App still works without changes (backward compatible)

---

## Sprint 11: OTA Firmware Update

### Micro: MCUboot + DFU
- [ ] Enable MCUboot as bootloader
- [ ] Implement DFU via BLE (SMP protocol)
- [ ] Firmware version readable via BLE characteristic
- **Acceptance**: Firmware updated wirelessly without physical access

### 🔄 Cross-validation
- **App validates Micro**: App triggers update, firmware runs new version after reboot

---

## Sprint 12: Production Hardening

### Micro: Stability
- [ ] Full test coverage (80%+)
- [ ] Power consumption profiling and optimization
- [ ] Stress testing (rapid connect/disconnect cycles, 1000+ toggles)
- [ ] Documentation complete
- **Acceptance**: Runs 30 days unattended without issues

### 🔄 Cross-validation
- **App validates Micro**: Automated test script: connect → toggle 100x → disconnect → repeat

