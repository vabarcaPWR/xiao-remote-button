# App Roadmap — xiao-remote-button

## Phase 1: Foundation (MVP)

### 1.1 Project Setup
- [ ] Create Flutter project targeting Android
- [ ] Add `flutter_blue_plus` dependency
- [ ] Configure Android BLE permissions (ACCESS_FINE_LOCATION, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
- [ ] Set minSdkVersion to 23 (Android 6.0+)
- **Acceptance**: App builds and requests BLE permissions on launch

### 1.2 BLE Scanner Screen
- [ ] Scan for BLE devices filtering by service UUID
- [ ] Display device name ("xiao-relay") and RSSI
- [ ] Tap device → connect
- [ ] Handle scan states: scanning, found, empty, error
- [ ] Handle Android 12+ permission flow
- **Acceptance**: Finds and lists xiao-relay device, tap connects

### 1.3 BLE Service Layer
- [ ] Connect to device and discover services
- [ ] Read relay state characteristic
- [ ] Write relay command characteristic (ON/OFF)
- [ ] Subscribe to Notify characteristic for state changes
- [ ] Handle pairing with PIN dialog
- [ ] Handle disconnection events → navigate back to scanner
- **Acceptance**: Full BLE communication works reliably

### 1.4 Relay Control Screen
- [ ] Large toggle button (ON/OFF)
- [ ] Visual state indicator (color/icon for relay state)
- [ ] Connection status banner
- [ ] Disconnect button
- [ ] Handle states: connecting, connected, disconnected, error
- **Acceptance**: User can toggle relay and see real-time state

---

## Phase 2: Enhancements

### 2.1 Auto-Off Timer
- [ ] Timer input (minutes) on control screen
- [ ] Send timer value to device via BLE characteristic
- [ ] Display countdown on screen
- [ ] Show notification when timer triggers auto-off
- **Acceptance**: User sets timer, relay turns off after time expires

### 2.2 UX Polish
- [ ] Remember last connected device (auto-reconnect)
- [ ] App state persistence (resume where left off)
- [ ] Dark/light theme
- [ ] Haptic feedback on toggle
- **Acceptance**: Smooth user experience without friction

### 2.3 Connection Reliability
- [ ] Auto-reconnect on transient BLE drops
- [ ] Background BLE connection (Android foreground service)
- [ ] Show "reconnecting..." state
- **Acceptance**: Connection recovers from brief signal loss

---

## Phase 3: Advanced

### 3.1 OTA Update UI
- [ ] Show current firmware version (read from device)
- [ ] Trigger DFU update from app
- [ ] Progress bar during firmware upload
- **Acceptance**: User can update device firmware from app

### 3.2 Multi-Device Support (Future)
- [ ] Save paired devices list
- [ ] Quick-switch between devices
- [ ] Per-device naming
- **Acceptance**: Manage multiple xiao-relay devices (when hardware supports it)
