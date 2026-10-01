import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CipherLab {
  static const MethodChannel _platform = MethodChannel("sdk_function_channel");
  static const String _defaultDeviceType = 'CipherLab';
  static const String _methodSetDeviceType = 'setDeviceType';
  static const String _methodTagScanned = 'chponTagScanned';
  static const String _methodTriggerMode = 'chpTrgMode';
  static const String _unsupportedMessage =
      'RFID รองรับเฉพาะเครื่อง CipherLab เท่านั้น';

  static bool _isDeviceSelected = false;
  static String _lastErrorMessage = '';

  static String get lastErrorMessage => _lastErrorMessage;

  static Future<T?> _invoke<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) {
    return _platform.invokeMethod<T>(method, arguments);
  }

  static Future<bool> isSupportedDevice() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final AndroidDeviceInfo androidInfo =
          await DeviceInfoPlugin().androidInfo;
      final String manufacturer = androidInfo.manufacturer.toLowerCase();
      final String brand = androidInfo.brand.toLowerCase();
      final String model = androidInfo.model.toLowerCase();

      return manufacturer.contains('cipherlab') ||
          brand.contains('cipherlab') ||
          model.contains('cipherlab');
    } catch (_) {
      return false;
    }
  }

  static Future<void> _ensureSupportedDevice() async {
    final bool isSupported = await isSupportedDevice();
    if (!isSupported) {
      throw PlatformException(
        code: 'UNSUPPORTED_DEVICE',
        message: _unsupportedMessage,
      );
    }
  }

  static Future<void> _ensureDevice({String? deviceType}) async {
    await _ensureSupportedDevice();

    if (_isDeviceSelected) {
      return;
    }

    final String targetDevice =
        (deviceType != null && deviceType.trim().isNotEmpty)
        ? deviceType.trim()
        : _defaultDeviceType;

    await _invoke<String>(_methodSetDeviceType, {
      'setDeviceType': targetDevice,
    });
    _isDeviceSelected = true;
  }

  static Future<String> setTagScannedListener(
    Function(String epc) onTagScanned,
  ) async {
    try {
      await _ensureDevice();
      _platform.setMethodCallHandler((MethodCall call) async {
        if (call.method != _methodTagScanned) {
          return null;
        }

        final String epc = (call.arguments ?? '').toString();
        if (epc.isEmpty) {
          return null;
        }

        onTagScanned(epc);
        return epc;
      });
      return "Listening";
    } catch (e) {
      debugPrint('CipherLab setTagScannedListener error: $e');
      return 'Error';
    }
  }

  static Future<String> init(String device) async {
    _lastErrorMessage = '';
    try {
      await _ensureDevice(deviceType: device);
      return 'Success';
    } on PlatformException catch (e) {
      _lastErrorMessage = e.message ?? 'CipherLab initialization failed';
      debugPrint('CipherLab init platform error: $_lastErrorMessage');
      return 'Error';
    } catch (e) {
      _lastErrorMessage = e.toString();
      debugPrint('CipherLab init error: $e');
      return 'Error';
    }
  }

  static Future<dynamic> scan(bool status) async {
    try {
      await _ensureDevice();
      return await _invoke<dynamic>(_methodTriggerMode, {"statusTrg": status});
    } catch (e) {
      debugPrint('CipherLab scan error: $e');
      return Future.error(e);
    }
  }

  static Future<void> release() async {
    _isDeviceSelected = false;
    _platform.setMethodCallHandler(null);
  }
}
