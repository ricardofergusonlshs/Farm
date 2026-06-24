# The Harvest Place Ja

Flutter app for fresh local food ordering, farm updates, customer accounts, orders, checkout, and admin/farmer management.

## Android release notes

The Android package ID is:

```text
com.theharvestplaceja.app
```

Before building for Google Play, create `android/key.properties` from `android/key.properties.template` and keep the real passwords/keystore file out of source control.

Recommended release test commands:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

Test the installed release build on real Android devices using both Wi-Fi and mobile data. Confirm Supabase login, signup, email confirmation, forgot password, product loading, images, cart, checkout, orders, admin screens, and notifications.
