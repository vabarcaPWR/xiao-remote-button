# FIP Remote Button

Android companion app for the FIP-remote-button BLE relay controller.

## Requirements

- Flutter SDK 3.11+
- JDK 17 or 21 (JDK 25 is incompatible with Kotlin Gradle plugin)
- Android SDK with build-tools

## Build

```bash
# Set JAVA_HOME to JDK 17 or 21
export JAVA_HOME=/path/to/jdk21

# Debug build
flutter run

# Release APK (fat)
flutter build apk --release

# Release APK (per-architecture, smaller)
flutter build apk --release --split-per-abi
```

## Test

```bash
flutter test
flutter analyze
```

## App Icon

Generated with `flutter_launcher_icons`. To regenerate:

```bash
dart run flutter_launcher_icons
```

Source images in `assets/icon/`.
