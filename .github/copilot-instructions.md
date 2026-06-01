# Copilot Instructions — xiao-remote-button

## 1. Project Overview

This project controls a 12V relay from a mobile phone via Bluetooth Low Energy (BLE) using a **Seeed XIAO nRF52840** microcontroller and the **nRF Connect SDK (Zephyr RTOS)**.

### Key Requirements

- **MCU**: Seeed XIAO nRF52840
- **SDK**: nRF Connect SDK (ncs) — no Arduino, no MicroPython
- **Language**: C
- **IDE**: VS Code with nRF Connect extension
- **Power**: Ultra-low power — device runs from a 12V car battery via a buck converter (12V → 3.3V)
- **Safety**: On any fault (watchdog, BLE disconnect timeout, exception), the relay MUST be turned OFF (fail-safe)
- **Design**: Minimalist — fewest components, simplest code

### Hardware Architecture

```
[12V Battery] ──┬── [Buck 12V→3.3V] ── [XIAO nRF52840]
                │                              │ GPIO
                └── [Relay 12V] ←── [MOSFET Driver] ←─┘
```

- The XIAO cannot drive the relay directly — a MOSFET driver circuit is required.
- The relay coil is powered directly from 12V.
- The XIAO controls the MOSFET gate via a GPIO pin.

### Mobile App

A companion mobile app (Android) to:
- Scan and connect to the device via BLE
- Toggle the relay ON/OFF
- Display the current relay state (on/off)

---

## 2. Firmware Development

### Framework & Toolchain

- **SDK**: nRF Connect SDK (based on Zephyr RTOS)
- **Build system**: CMake + west
- **BLE stack**: Zephyr Bluetooth (HCI, GATT)
- **Power management**: Zephyr PM subsystem (System OFF, idle states)

### Directory Structure

```
micro/
├── CMakeLists.txt
├── prj.conf                  # Kconfig project configuration
├── boards/                   # Board overlays for xiao_ble
├── src/
│   ├── main.c
│   ├── relay/                # Relay control (GPIO + fail-safe logic)
│   ├── ble/                  # BLE service definition and handlers
│   └── power/                # Power management (sleep, watchdog)
├── include/
│   └── *.h
└── test/                     # Ceedling unit tests
```

### Coding Conventions

- Use `snake_case` for functions/variables, `UPPER_SNAKE_CASE` for macros, `_t` suffix for types
- Return `int` error codes (0 = success) or use Zephyr's error codes
- Validate all pointer parameters at function entry
- Use Zephyr logging macros (`LOG_INF`, `LOG_WRN`, `LOG_ERR`) — never `printf`
- Prefer static allocation — no `malloc` in production code
- Private functions: always `static`
- Allman brace style, 4-space indent, 120-char line limit
- **No file headers**: No `@file` blocks or top-of-file banners in `.c` files
- **No comments in `.c` files**: Code must be self-explanatory through clear naming
- **DRY**: Extract shared logic into helper functions
- **Self-documenting code**: If a comment is needed, rename the symbol instead
- Public headers: include guard + `extern "C"` wrapper + Doxygen for public API
- Use `if (!ptr)` instead of `if (ptr == NULL)`
- Single-statement if without braces:
  ```c
  if (!ptr)
      return -EINVAL;
  ```
- Format with `.clang-format` after every edit

### Hardware Pin Assignment

| Signal | Pin | Description |
|--------|-----|-------------|
| Relay MOSFET gate | P0.02 (D0) | Active HIGH → relay ON |

### BLE Protocol

Custom GATT service for relay control:

| Characteristic | Properties | Description |
|----------------|-----------|-------------|
| Relay Command | Write | `0x01` = ON, `0x00` = OFF |
| Relay State | Read | Current state: `0x01` / `0x00` |
| Relay State | Notify | Pushed on every state change |

**Security**: Just Works pairing (no PIN required). Bonding supported.

### Fail-Safe Design

The relay MUST default to OFF. Implementation rules:

1. **Watchdog timer (15s)** — if firmware hangs, system resets → relay OFF
2. **BLE disconnect timeout (30s)** — if phone disconnects for > 30 seconds → relay OFF
3. **Reconnection grace** — if phone reconnects within 30s, relay keeps its current state
4. **GPIO default state** — configure P0.02 as output LOW at boot (relay OFF)
5. **Startup state** — relay always starts OFF regardless of previous state
6. **Priority order**: Safety > Convenience. When in doubt, turn relay OFF.

### Agent & Skill References

| Task | Use |
|------|-----|
| New firmware feature | `@firmware` agent + `skill: firmware-coding` |
| New component/module | `@firmware` agent + prompt `firmware-new-component` |
| BLE service work | `@firmware` agent + prompt `firmware-ble-service` |
| Writing tests | `@tdd-guide` agent + `skill: ceedling-testing` |
| TDD workflow | `@tdd-guide` agent + `skill: tdd-workflow` |

---

## 3. Mobile App Development

### Technology

- **Framework**: Flutter (Dart)
- **Platform**: Android only (MVP)
- **BLE library**: `flutter_blue_plus`
- **Features (MVP)**:
  - BLE scan and connect to xiao-remote-button device
  - Toggle relay ON/OFF button
  - Display relay state (on/off indicator)
  - Handle BLE disconnection gracefully

### Directory Structure

```
app/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── scanner/          # BLE device scanner
│   │   └── control/          # Relay control screen
│   ├── services/
│   │   └── ble_service.dart  # BLE communication layer
│   └── models/
│       └── relay_state.dart
└── test/
```

### Conventions

- Follow Dart/Flutter naming: `camelCase` methods, `PascalCase` classes
- Handle all errors explicitly — no unhandled exceptions
- Every screen handles: loading, error, empty, connected/disconnected states
- Comments in English
- Format with `dart format`

### Agent & Skill References

| Task | Use |
|------|-----|
| New screen/widget | `@app` agent + prompt `app-new-screen` |
| BLE integration | `@app` agent |
| UI/UX questions | `@app` agent |

---

## 4. Testing Strategy

All development follows **TDD (Test-Driven Development)**:

1. **RED** — Write a failing test
2. **GREEN** — Write minimal code to pass
3. **REFACTOR** — Improve while keeping tests green

### Firmware Tests

- Framework: **Ceedling** (Unity + CMock)
- Location: `micro/test/`
- Run: `ceedling test:<module>` or `ceedling test:all`
- Coverage: `ceedling gcov:all` — target 80%+
- One assert per test, descriptive test names (`test_relay_turns_off_when_ble_disconnects`)

### App Tests

- Widget tests for each screen state
- Unit tests for BLE service logic
- Run: `flutter test`

### References

| Task | Use |
|------|-----|
| Writing Ceedling tests | `skill: ceedling-testing` |
| Full TDD cycle | `@tdd-guide` agent + `skill: tdd-workflow` |

---

## 5. Documentation

- All documentation in **English**
- Use **Mermaid** for diagrams
- Roadmaps in `docs/` with actionable checklists
- Architecture decisions as ADRs in `docs/adr/`

### Agent Reference

| Task | Use |
|------|-----|
| Update roadmaps | `@docs` agent |
| Write ADRs | `@docs` agent |
| Architecture diagrams | `@docs` agent |

---

## 6. Planning & Refactoring

| Task | Use |
|------|-----|
| Plan complex features | `@planner` agent |
| Dead code cleanup | `@refactor-cleaner` agent |
| Code consolidation | `@refactor-cleaner` agent |

---

## 7. Git Conventions

### Commit Messages

Use conventional commits:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` code restructure without behavior change
- `test:` adding/fixing tests
- `chore:` build, CI, tooling

### Branch Strategy

- `main` — stable, always builds
- `feat/<name>` — feature branches
- `fix/<name>` — bugfix branches

---

## 8. IA rules
- Do not comit any code to the repository
