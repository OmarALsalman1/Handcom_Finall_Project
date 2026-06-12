# flutter_application_1

A new Flutter project.

## Backend connection

The app talks to the Django backend (see `F_Project/Handcom_F`) at the URL
configured in `lib/core/config/api_config.dart`. By default it points to
`http://10.0.2.2:8000/api/v1`, which is the Android emulator's alias for
`localhost` on the host machine — run the backend with
`python manage.py runserver` and the default config works as-is.

To point at a different host (e.g. a physical device on the same network, or
a deployed server), pass `--dart-define` when running/building:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-ip-or-host>:8000/api/v1
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
