# App Architecture — xiao-remote-button

## Overview

Minimal Android companion app built with Flutter to control a BLE relay device. Connects to a single xiao-relay device, toggles relay state, and displays real-time feedback.

## Architecture Diagram

```mermaid
graph TD
    subgraph UI Layer
        SCANNER[Scanner Screen]
        CONTROL[Control Screen]
    end

    subgraph Service Layer
        BLE_SVC[BLE Service<br/>flutter_blue_plus]
        TIMER_SVC[Timer Service]
    end

    subgraph Model Layer
        RELAY_STATE[Relay State Model]
        DEVICE[Device Model]
    end

    SCANNER -->|device selected| BLE_SVC
    BLE_SVC -->|connected| CONTROL
    CONTROL -->|toggle| BLE_SVC
    BLE_SVC -->|notify| RELAY_STATE
    RELAY_STATE -->|update| CONTROL
    CONTROL -->|set timer| TIMER_SVC
    TIMER_SVC -->|write BLE| BLE_SVC
```

## Screen Flow

```mermaid
stateDiagram-v2
    [*] --> Scanner
    Scanner --> Connecting: Device tapped
    Connecting --> Control: Connected + paired
    Connecting --> Scanner: Connection failed
    Control --> Scanner: Disconnected / Back
    Control --> Control: Toggle relay
```

## Module Responsibilities

### Scanner Screen (`screens/scanner/`)
- Start/stop BLE scan filtered by relay service UUID
- Display discovered devices with name + signal strength
- Handle states: scanning, found, empty, BLE off, permission denied
- Tap → connect to device

### Control Screen (`screens/control/`)
- Large relay toggle button (ON/OFF)
- State indicator (color: green=ON, gray=OFF)
- Connection status bar (connected / reconnecting / disconnected)
- Timer input for auto-off feature (Phase 2)
- Disconnect button → return to scanner

### BLE Service (`services/ble_service.dart`)
- Singleton managing one active connection
- API:
  - `scan()` → Stream of discovered devices
  - `connect(device)` → Future (handles pairing)
  - `disconnect()`
  - `sendCommand(RelayCommand.on / .off)`
  - `readState()` → RelayState
  - `stateStream` → Stream<RelayState> (from Notify)
- Handles:
  - Service/characteristic discovery
  - PIN pairing dialog
  - Auto-disconnect cleanup
  - Connection state events

### Timer Service (`services/timer_service.dart`) — Phase 2
- Send timer duration to device
- Track countdown locally for UI display
- Handle timer-triggered-off notification

### Models

```dart
enum RelayState { on, off, unknown }

enum ConnectionState { disconnected, connecting, connected, error }

class RelayDevice {
  final String id;
  final String name;
  final int rssi;
}
```

## BLE Communication Protocol

```mermaid
sequenceDiagram
    participant App
    participant Device

    App->>Device: Connect
    Device->>App: Pairing request (PIN)
    App->>Device: PIN response
    App->>Device: Discover services
    App->>Device: Enable Notify on State char
    App->>Device: Read State char → 0x00 (OFF)

    Note over App: User taps ON
    App->>Device: Write Command char → 0x01
    Device->>App: Notify State → 0x01 (ON)

    Note over App: User taps OFF
    App->>Device: Write Command char → 0x00
    Device->>App: Notify State → 0x00 (OFF)
```

## State Management

Simple approach for MVP:

- **ChangeNotifier + Provider** (or equivalent lightweight pattern)
- BLE Service exposes Streams
- Screens listen to streams and rebuild on state change
- No complex state management needed for single-device, single-screen interaction

## Error Handling Strategy

| Scenario | App Behavior |
|----------|-------------|
| BLE off | Show "Enable Bluetooth" message + settings link |
| Permission denied | Show explanation + retry button |
| Device not found | Show "No devices found" + rescan button |
| Connection failed | Show error + retry button |
| Pairing rejected | Show "Pairing failed" + retry |
| Unexpected disconnect | Show banner "Disconnected", auto-navigate to scanner after 5s |
| Write failed | Show toast "Command failed", retry automatically once |

## Directory Structure

```
app/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── scanner/
│   │   │   └── scanner_screen.dart
│   │   └── control/
│   │       └── control_screen.dart
│   ├── services/
│   │   ├── ble_service.dart
│   │   └── timer_service.dart
│   ├── models/
│   │   ├── relay_state.dart
│   │   └── relay_device.dart
│   └── widgets/
│       ├── relay_toggle_button.dart
│       └── connection_banner.dart
├── test/
│   ├── services/
│   │   └── ble_service_test.dart
│   └── screens/
│       ├── scanner_screen_test.dart
│       └── control_screen_test.dart
├── pubspec.yaml
└── android/
    └── app/src/main/AndroidManifest.xml   # BLE permissions
```

## Design Decisions

1. **Single device connection** — Simplifies UX and BLE lifecycle management
2. **No local persistence (MVP)** — No saved state, always fresh from device
3. **Notify over polling** — Real-time state via BLE notifications, no periodic reads
4. **Thin service layer** — BLE service encapsulates all Bluetooth complexity; screens stay simple
5. **No background service (MVP)** — Connection only while app is in foreground
6. **Provider for state** — Lightest viable state management for this scope
