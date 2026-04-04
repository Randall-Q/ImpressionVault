# Impression Vault

Cross-platform Flutter application for collecting customer demographics and capturing customer images.

## Architecture

- UI Framework: Flutter (mobile + desktop form factors)
- Database: SQLite (sqflite / sqflite_common_ffi)
- Image Storage: File system (recommended for larger binary data)
- Image Metadata: SQLite table with image path, customer link, timestamps

This approach avoids storing large blobs in SQLite, keeps the database smaller, and improves sync/backup flexibility.

## Implemented Workflow

1. Splash screen on startup
2. Login screen
3. Dashboard listing customers and image counts
4. Add/Edit customer demographics
5. Camera capture screen
6. Captured images shown in ribbon/list under or beside camera preview
7. Tap image to open full-screen viewer
8. Delete image from full-screen viewer
9. Return to demographics screen for edits
10. Done returns to dashboard with updated image count

## Project Structure

- lib/main.dart
- lib/app.dart
- lib/data/app_database.dart
- lib/models/customer.dart
- lib/models/customer_summary.dart
- lib/models/customer_image_record.dart
- lib/screens/splash_screen.dart
- lib/screens/login_screen.dart
- lib/screens/dashboard_screen.dart
- lib/screens/customer_form_screen.dart
- lib/screens/camera_capture_screen.dart
- lib/screens/image_viewer_screen.dart

## Dependencies

Declared in pubspec.yaml:

- sqflite
- sqflite_common_ffi
- path
- path_provider
- camera
- intl

## Run Instructions

1. Install Flutter SDK and add flutter to PATH.
2. From this folder, run:

   flutter pub get
   flutter run

If you want platform folders generated explicitly (android/ios/windows/linux/macos/web), run:

flutter create .

## Notes

- Login is local/demo validation only.
- Web is not enabled in the current SQLite implementation.
- If no camera is available, the capture screen shows a camera unavailable message.
