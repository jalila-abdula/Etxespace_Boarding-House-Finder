# etxespace

A new Flutter project.

## Cloudinary image uploads

Property photos and payment proof images use Cloudinary unsigned uploads. In the
Cloudinary console, create an upload preset with signing mode set to
**Unsigned**. This project defaults to cloud name `qtr3s3f7` and preset
`Etxespace_Cloud`.

Run the app with your account settings (PowerShell):

```powershell
flutter run
```

For a different Cloudinary account, set `CLOUDINARY_CLOUD_NAME` and
`CLOUDINARY_UPLOAD_PRESET` with `--dart-define`. Pass those same values to
`flutter build` for release builds.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
