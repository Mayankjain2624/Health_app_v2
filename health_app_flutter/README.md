# Health App Flutter

## Overview
A simple Flutter app that reads health data (Android Health Connect / iOS HealthKit) via the `health` plugin, displays daily steps and recent workouts, and syncs to a Node.js + MongoDB backend. Architecture follows BLoC + Repository + Service patterns.

## Run

1. Ensure Flutter SDK is installed and an Android/iOS device/emulator is available.
2. Update backend URL in `lib/core/config.dart`.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Build APK (Android)

```bash
flutter build apk
```

## Permissions
- Android: Health Connect permissions are requested at runtime by the plugin.
- iOS: Add HealthKit entitlements and `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` in `ios/Runner/Info.plist`.

## Background Sync
WorkManager registers a periodic task that fetches recent workouts and syncs to backend every hour.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
