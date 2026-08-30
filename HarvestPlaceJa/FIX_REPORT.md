# The Harvest Place Ja — Android Release Fix Report

## What was fixed

- Kept the original Dart library setup: `library harvest_place_app;` and `part of harvest_place_app;`.
- Added release/main Android internet permission to `android/app/src/main/AndroidManifest.xml`.
- Changed Android app label to `The Harvest Place Ja`.
- Added Android custom-scheme deep links for:
  - `farm://auth-callback/`
  - `farm://reset-password/`
- Repaired `android/build.gradle.kts` so it is a valid Flutter root Gradle file.
- Repaired `android/app/build.gradle.kts`:
  - plugin is now `com.android.application`
  - `namespace` is `com.theharvestplaceja.app`
  - `applicationId` is `com.theharvestplaceja.app`
  - `compileSdk` is `35`
  - `targetSdk` is `35`
  - debug signing was removed from release
  - release signing now uses `android/key.properties` when provided
- Updated `MainActivity.kt` package to `com.theharvestplaceja.app` and moved it to the matching Kotlin folder.
- Updated Play Store share URL in `lib/app/app_config.dart` to use `com.theharvestplaceja.app`.
- Replaced placeholder app metadata in `pubspec.yaml`, `README.md`, `web/manifest.json`, and `web/index.html`.
- Added `android/key.properties.template`.
- Added `.gitignore` entries to keep keystore files and passwords out of source control.

## Important next step: release signing

Create a real Android upload key and then create this file locally:

```text
android/key.properties
```

Use the template:

```text
android/key.properties.template
```

Never upload the real `key.properties` or `.jks` file publicly.

## Wi-Fi issue investigation

The original release manifest did not include `android.permission.INTERNET`, while debug/profile did. That can cause release-installed builds to fail loading Supabase, images, products, login, and orders.

If the fixed release build works on mobile data but still fails on one Wi-Fi network only, then the likely cause is outside the app: DNS filtering, captive portal, router firewall, ISP filtering, or blocked WebSocket/Supabase endpoint. Test on another Wi-Fi network and capture the exact Supabase/network error.

## Test commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

Then install/test on a real Android phone using both Wi-Fi and mobile data.
