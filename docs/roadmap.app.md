# App Roadmap — xiao-remote-button

> ⚠️ This roadmap is developed in parallel with `roadmap.micro.md`.
> Each sprint delivers a complete feature validated end-to-end:
> the app is validated with the firmware and the firmware is validated with the app.
> Sprints are synchronized with the firmware roadmap.

---

## Sprint 1: Setup (Independent)

### App: Project Setup
- [x] Create Flutter project targeting Android
- [x] Add `flutter_blue_plus` dependency
- [x] Configure Android BLE permissions (ACCESS_FINE_LOCATION, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
- [x] Set minSdkVersion to 23 (Android 6.0+)
- [x] Create basic app structure (screens/, services/, models/)
- **Acceptance**: App builds, installs on phone, requests BLE permissions
- **Validates with Micro**: N/A (independent)

---

## Sprint 2: BLE Advertising + Scanner

### App: BLE Scanner Screen
- [x] Scan for BLE devices filtering by custom relay service UUID
- [x] Display device name ("xiao-relay") and RSSI
- [x] Handle scan states: scanning, found, empty, BLE off, permission denied
- [x] Handle Android 12+ permission flow
- [x] Tap device → initiate connection (next sprint)
- **Acceptance**: Finds and lists "xiao-relay" device in scan results

### 🔄 Cross-validation ✅
- [x] **App validates Micro**: Device found → firmware advertising and UUID correct
- [x] **Micro validates App**: App shows "xiao-relay" in scan list

---

## Sprint 3: BLE Connection + Pairing

### App: Connection + Just Works Pairing
- [x] Connect to selected device (no PIN required)
- [x] Discover GATT services after connection
- [x] Handle connection states: connecting, connected, failed, disconnected
- [x] Navigate to control screen on successful connection
- [x] Navigate back to scanner on disconnect
- **Acceptance**: App connects directly (no PIN dialog), transitions to control screen

### 🔄 Cross-validation ✅
- [x] **App validates Micro**: If connection rejected or services not found → firmware config wrong
- [x] **Micro validates App**: Firmware logs successful connection → app must show "connected"

---

## Sprint 4: Relay Control via BLE

### App: Control Screen + Write Command
- [x] Large toggle button (ON/OFF)
- [x] Write to relay command characteristic (0x01=ON, 0x00=OFF)
- [x] Read relay state characteristic on connection (initial sync)
- [x] Visual state indicator (color: green=ON, gray=OFF)
- [x] Connection status banner
- [x] Disconnect button
- [x] Widget tests for all screen states
- **Acceptance**: Tap toggle → relay physically switches

### 🔄 Cross-validation ✅
- [x] **App validates Micro**: If relay doesn't switch on write → firmware GATT handler wrong
- [x] **Micro validates App**: Firmware confirms state change → app must reflect it in UI
- [x] **Physical check**: Multimeter on P0.02 confirms the app controls hardware

---

## Sprint 5: State Notifications

### App: Real-time State via Notify
- [ ] Subscribe to relay state Notify characteristic
- [ ] Update UI immediately on notification received
- [ ] Handle edge case: state changed while app was subscribing
- [ ] Unit test for BLE service notify stream
- **Acceptance**: State updates in real-time without polling

### 🔄 Cross-validation
- **App validates Micro**: If notifications don't arrive → firmware CCC/notify broken
- **Micro validates App**: Firmware sends notify → app UI must update within 100ms

---

## Sprint 6: Fail-Safe Feedback

### App: Disconnect & Reconnect UX
- [ ] Detect BLE disconnection → show "Disconnected" banner
- [ ] Auto-navigate to scanner after 5s without reconnection
- [ ] On reconnect: read current state (may have changed due to fail-safe)
- [ ] Show notification if relay was turned OFF by fail-safe during disconnect
- [ ] Handle states: connecting, connected, reconnecting, disconnected, error
- **Acceptance**: User understands what happened when fail-safe triggered

### 🔄 Cross-validation
- **App validates Micro**: After 30s disconnect, reconnect → read state should be OFF
- **Micro validates App**: Firmware fail-safe fires → on next connect, app reads correct state
- **Stress test**: Toggle ON → kill app → wait 30s → reopen → relay shows OFF

---

## Sprint 7: Power Optimization (App-side)

### App: Connection Interval Awareness
- [ ] Request appropriate connection interval via BLE parameters
- [ ] Handle occasional latency gracefully (don't spam writes)
- [ ] Test stability with longer intervals (500ms)
- **Acceptance**: App works reliably with power-optimized connection
- **Validates with Micro**: Connection stable with reduced power

---

## Sprint 8: Auto-Off Timer

### App: Timer UI
- [ ] Timer input on control screen (minutes picker or slider)
- [ ] Send timer value to device via BLE characteristic (uint16, minutes)
- [ ] Display countdown locally (synced with device)
- [ ] Show notification/toast when timer triggers auto-off
- [ ] Cancel timer button (writes 0)
- [ ] Unit tests for timer service
- **Acceptance**: User sets timer, sees countdown, relay turns off on time

### 🔄 Cross-validation
- **App validates Micro**: If relay doesn't off at expected time → firmware timer wrong
- **Micro validates App**: Firmware sends notify on timer-off → app shows correct state

---

## Sprint 9: Persistent Configuration

### App: Config Screen
- [ ] Read device name from BLE config characteristic
- [ ] Allow changing device name (write to config characteristic)
- [ ] Read/write default timer value
- [ ] Confirm changes saved (read-back after write)
- **Acceptance**: Configuration changes persist across device reboots

### 🔄 Cross-validation
- **App validates Micro**: Write config → reboot device → read config → must match

---

## Sprint 10: Multi-Relay (UI Ready)

### App: Extensible UI
- [ ] Relay list/grid instead of single button (but only 1 item for now)
- [ ] Each relay shows: name, state, toggle
- [ ] Architecture ready for N relays (from BLE discovery)
- **Acceptance**: UI works with 1 relay, architecture ready for more
- **Validates with Micro**: Backward compatible — existing firmware works unchanged

---

## Sprint 11: OTA Update UI

### App: Firmware Update Flow
- [ ] Read firmware version from BLE characteristic
- [ ] Display current version on settings/info screen
- [ ] Trigger DFU via SMP protocol (McuManager library)
- [ ] Progress bar during firmware upload
- [ ] Handle update success/failure
- **Acceptance**: User can update device firmware from app

### 🔄 Cross-validation
- **App validates Micro**: After OTA, device runs new version (version string changes)

---

## Sprint 12: UX Polish & Hardening

### App: Production Quality
- [ ] Remember last connected device (auto-reconnect on app launch)
- [ ] Auto-reconnect on transient BLE drops
- [ ] Background BLE connection (Android foreground service)
- [ ] Dark/light theme
- [ ] Haptic feedback on toggle
- [ ] Full test coverage (widget + unit + integration)
- **Acceptance**: Smooth, reliable user experience

### 🔄 Cross-validation
- **App validates Micro**: Automated test: connect → toggle 100x → disconnect → repeat 10x
