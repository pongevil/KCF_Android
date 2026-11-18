/// Compile-time runtime configuration for production and local development.
///
/// Production is the safe default. Local API routing and bundled mock data
/// must be enabled explicitly with `--dart-define` flags.
class AppEnvironment {
  AppEnvironment._();

  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const bool useLocalApi = bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: false,
  );

  static bool get isProduction => name.toLowerCase() == 'production';
}
