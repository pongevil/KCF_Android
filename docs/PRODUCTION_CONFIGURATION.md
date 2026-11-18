# Production configuration

`lib/main.dart` is the production entrypoint. The application uses the server
saved from Server Configuration, defaulting to `http://10.10.60.45:98`.

Runtime defaults:

- `APP_ENV=production`
- `USE_LOCAL_API=false`
- API paths are centralized in `lib/src/core/network/api_endpoints.dart`
- Print API uses the scheme and host saved from Server Configuration, replaces
  the configured gateway port with `48766`, and calls `/api/v1/print`.
- Test doubles belong under `test/`; runtime code never loads mock menu,
  barcode, or business data.

Local API routing must be enabled explicitly:

```sh
flutter run --dart-define=APP_ENV=development --dart-define=USE_LOCAL_API=true
```

The files under `assets/config/` and `assets/i18n/` are safe application
defaults used only when remote configuration or localization cannot be loaded.
They are not business transaction mock data.

Before release, configure the final Android application ID, Firebase project,
and signing key together. Changing the application ID creates a separate app
and prevents in-place upgrades from the previous package.
