class DeviceConnectionSettings {
  const DeviceConnectionSettings({
    this.packingLine = '',
  });

  static const defaults = DeviceConnectionSettings();

  final String packingLine;
}

enum ConnectionTestStatus { success, failure }

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.status,
    required this.elapsed,
    this.error,
  });

  final ConnectionTestStatus status;
  final Duration elapsed;
  final Object? error;

  bool get isSuccess => status == ConnectionTestStatus.success;
}
