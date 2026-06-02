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
- [x] Subscribe to relay state Notify characteristic
- [x] Update UI immediately on notification received
- [x] Handle edge case: state changed while app was subscribing
- [x] Unit test for BLE service notify stream
- **Acceptance**: State updates in real-time without polling

### 🔄 Cross-validation
- **App validates Micro**: If notifications don't arrive → firmware CCC/notify broken
- **Micro validates App**: Firmware sends notify → app UI must update within 100ms

---

## Sprint 6: LED Status Feedback (App Awareness)

### App: Connection State UX (Revised)
- [x] Update status banner to reflect new LED code semantics:
  - Connected: "Connected — relay ON/OFF"
  - Disconnected: "Disconnected — device running autonomously"
- [x] On disconnect: show informational banner (device keeps running)
- [x] Remove old "Returning to scanner" auto-navigation (device works without app)
- [x] Add manual "Back to scanner" button on disconnect state
- [x] Widget tests for new disconnect behavior (15 tests total)
- **Acceptance**: User understands device continues working after disconnect

### 🔄 Cross-validation ✅
- [x] **App validates Micro**: LED color matches app state indicator
- [x] **Micro validates App**: Disconnect → app shows "autonomous" message, not error

---

## Sprint 7: Relay Timer UI

### App: Timer Configuration
- [x] Timer input on control screen (picker: 1 min – 6 hours, or "No timer")
- [x] "No timer" = indefinite ON (device will auto-off at 10 min)
- [x] Send timer value to device via BLE characteristic (uint16, seconds)
- [x] Display countdown (read Timer Remaining characteristic + local sync)
- [x] Subscribe to Timer Remaining Notify for real-time countdown
- [x] Show notification/toast when timer triggers auto-off
- [x] Cancel timer button (sends explicit relay OFF)
- [x] Widget tests for timer UI states (19 tests total)
- **Acceptance**: User sets timer, sees countdown, relay turns off on time

### 🔄 Cross-validation ✅
- [x] **App validates Micro**: Set 60s timer → relay OFF at 60s ✓
- [x] **Micro validates App**: Timer remaining decrements; notify fires on expiry ✓
- [x] **App validates Micro**: Set no timer → device auto-off at 10 min ✓

---

## Sprint 8: Autonomous Operation Awareness

### App: Reconnect After Autonomous Period
- [x] On reconnect: read current relay state (may have changed due to timer expiry)
- [x] Read timer remaining (0 = expired or no timer)
- [x] Show informational message if relay was turned OFF by timer during disconnect
- [x] Handle states: connecting, connected, disconnected (no reconnecting/error needed)
- [x] Widget tests for reconnection scenarios (21 tests total)
- **Acceptance**: User reopens app after timer expired → sees OFF with explanation

### 🔄 Cross-validation ✅
- [x] **App validates Micro**: Timer expired during disconnect → snackbar shown (unit test verified)
- [x] **Micro validates App**: Reconnect before timer → reads ON + remaining time (unit test verified)
- **Note**: BlueZ caching prevents reliable reconnection in Linux desktop; full validation on Android

---

## Sprint 9: Fail-Safe Feedback (Revised)

### App: Watchdog/Exception Awareness
- [x] On reconnect after unexpected device reset: relay will be OFF (startup default)
- [x] Detect "device rebooted" condition via uptime characteristic (<30s = recent reboot)
- [x] Show notification: "Device restarted — relay OFF (safety)"
- [x] No auto-reconnect needed (user opens app manually)
- [x] Widget tests for reconnection scenarios (22 tests total)
- **Acceptance**: User understands when fail-safe (watchdog/crash) triggered vs timer expiry

### 🔄 Cross-validation ✅
- [x] **Stress test**: Power cycle device while ON → reopen app → shows "Device restarted" (unit test verified)
- [x] **Hardware**: Power cycle confirmed relay OFF via LED ✓

---

## Sprint 10: Power Optimization (App-side)

### App: Connection Interval Awareness
- [x] Connection works with peripheral-requested intervals (100–500ms, latency 4)
- [x] Stability verified: 5 toggle cycles over 38s without errors
- [x] No special app changes needed — peripheral controls interval negotiation
- **Acceptance**: App works reliably with power-optimized connection ✅
- **Validates with Micro**: Connection stable with reduced power ✅

---

## Sprint 11: Production Hardening

### App: Production Quality
- [x] Remember last connected device (auto-connect on app launch)
- [x] Dark/light theme (follows system ThemeMode)
- [x] Haptic feedback on toggle
- [x] Test coverage: 25 tests (widget + unit) — 0 failures
- [x] Timer drift warning UX (shows amber snackbar if drift >5s)
- **Acceptance**: Smooth, reliable user experience ✅

### 🔄 Cross-validation
- [x] **App validates Micro**: Automated test: connect → set timer → disconnect → verify timing ✅
