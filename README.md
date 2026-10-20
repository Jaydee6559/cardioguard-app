# CardioGuard

CardioGuard connects to an Arduino wearable over Bluetooth Low Energy (BLE). The Android and iOS Device & Sensors screen scans for devices, displays their advertised name (or **Unnamed BLE device**) and identifier, and connects to the HM-10 GATT notification service. Device names are not used to identify the Arduino.

## Arduino BLE profile

- BLE service: `0000FFE0-0000-1000-8000-00805F9B34FB`
- Notification/indication characteristic: `0000FFE1-0000-1000-8000-00805F9B34FB`
- The characteristic must support notifications or indications.
- Send UTF-8 text lines terminated by LF or CRLF. The app subscribes to updates and does not read the characteristic.

Supported lines:

```text
HR:78
HR:NA
G:1.02
STATE:NORMAL
STATE:FALL_PENDING
STATE:EMERGENCY
EVENT:SYSTEM_READY
EVENT:SOS
EVENT:POSSIBLE_FALL
EVENT:FALL_CANCELLED
EVENT:FALL_EMERGENCY
EVENT:EMERGENCY_CLEARED
EVENT:USER_OK
```

The Arduino remains authoritative for fall and emergency state. A possible-fall report is shown as a warning; CardioGuard raises an emergency notification only for an Arduino SOS, `EVENT:FALL_EMERGENCY`, or `STATE:EMERGENCY`. The app does not infer falls from acceleration or create SpO₂, GPS, battery, or historical sensor readings. Readings remain visible with their receive time and become stale after disconnect or when no fresh data arrives.

Only one central connection may be accepted by some HM-10-compatible modules. Disconnect nRF Connect and other BLE clients before connecting CardioGuard. If the profile is not found, the app displays the discovered UUIDs and characteristic properties.

## Platform permissions

- **Android 12+ (API 31+)**: allow Nearby devices (Bluetooth scan and connect) when prompted.
- **Android 11 and older**: allow Location while using the app and enable the device's Location service while scanning, as required by Android's BLE scanning rules.
- **iOS**: allow Bluetooth access. The usage descriptions are in `ios/Runner/Info.plist`.

The iOS project is included, but building/running it requires macOS and Xcode; it cannot be built on Windows.

## Development and tests

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
```

The protocol parser and BLE lifecycle have focused unit tests using a fake transport. Validate actual radio discovery, notification delivery, permissions, and HM-10 firmware behavior with the target hardware.
