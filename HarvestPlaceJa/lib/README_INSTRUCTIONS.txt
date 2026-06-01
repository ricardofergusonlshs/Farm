Fix for Android release build browser notification error

Put these 3 Dart files inside your Flutter project's lib folder:

1. browser_notifications.dart
2. browser_notifications_stub.dart
3. browser_notifications_web.dart

Do not change main.dart.

After adding/replacing the files:
- Save all files
- Commit changes
- Push to GitHub
- Start a new Codemagic build

Build settings:
- Android only
- Release mode
- Branch: main
- Project path: HarvestPlaceJa
