# Firmware Roadmap — xiao-remote-button

## Phase 1: Foundation (MVP)

### 1.1 Project Setup
- [ ] Initialize nRF Connect SDK project with CMake + west
- [ ] Configure `prj.conf` for XIAO nRF52840 (BLE, GPIO, logging)
- [ ] Create board overlay for `xiao_ble_nrf52840`
- [ ] Verify build + flash pipeline works
- **Acceptance**: `west build` succeeds, LED blinks on device

### 1.2 Relay Control Module
- [ ] Configure P0.02 (D0) as GPIO output, default LOW
- [ ] Implement `relay_init()`, `relay_on()`, `relay_off()`, `relay_get_state()`
- [ ] Verify fail-safe: GPIO LOW on boot before any logic runs
- [ ] Write Ceedling unit tests for relay logic
- **Acceptance**: Relay toggles via direct function calls, starts OFF on every boot

### 1.3 BLE Service — Relay Control
- [ ] Define custom GATT service with UUID
- [ ] Implement Write characteristic (0x01=ON, 0x00=OFF)
- [ ] Implement Read characteristic (current state)
- [ ] Implement Notify characteristic (state change push)
- [ ] Configure advertising with device name "xiao-relay"
- [ ] Implement pairing with fixed 6-digit PIN
- [ ] Test connection from nRF Connect mobile app
- **Acceptance**: Can toggle relay from nRF Connect app, state reads correctly

### 1.4 Fail-Safe Mechanisms
- [ ] Implement BLE disconnect callback → start 30s timer
- [ ] On timer expiry without reconnection → relay OFF
- [ ] On reconnection within 30s → cancel timer, keep state
- [ ] Configure hardware watchdog (15s timeout)
- [ ] Feed watchdog in main loop
- [ ] Write tests for timeout logic
- **Acceptance**: Relay turns OFF 30s after phone disconnect; watchdog reset recovers to relay OFF

### 1.5 Power Management
- [ ] Enable Zephyr idle thread (automatic sleep between events)
- [ ] Configure BLE connection intervals for low power (e.g., 100–500ms)
- [ ] Measure current consumption (target: < 5mA idle connected)
- **Acceptance**: Measured current in idle+connected state is acceptable for car battery

---

## Phase 2: Enhancements

### 2.1 Timer Auto-Off
- [ ] Add BLE characteristic for timer duration (Write, uint16, minutes)
- [ ] Implement countdown → relay OFF when timer expires
- [ ] Notify app when timer triggers auto-off
- [ ] Cancel timer on manual OFF or new timer write
- **Acceptance**: Relay auto-off after configured minutes, app shows countdown

### 2.2 Multi-Relay Architecture (Extensible)
- [ ] Refactor relay module to support relay index parameter
- [ ] Abstract GPIO pin mapping via config/devicetree
- [ ] Keep single-relay behavior unchanged (index 0)
- **Acceptance**: Architecture supports N relays, current behavior unchanged

### 2.3 Persistent Configuration
- [ ] Store device name in NVS/settings subsystem
- [ ] Store default timer value in NVS
- [ ] Store PIN in NVS (allow change via BLE)
- **Acceptance**: Config survives power cycle

---

## Phase 3: Hardening

### 3.1 OTA Firmware Update
- [ ] Enable MCUboot as bootloader
- [ ] Implement DFU via BLE (SMP protocol)
- [ ] App triggers update flow
- **Acceptance**: Firmware updated wirelessly without physical access

### 3.2 Production Readiness
- [ ] Full test coverage (80%+)
- [ ] Power consumption profiling and optimization
- [ ] Stress testing (rapid connect/disconnect cycles)
- [ ] Documentation complete
- **Acceptance**: Runs 30 days unattended without issues
