import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef ZebraTagScannedCallback =
    FutureOr<void> Function(String epc, String rssi);
typedef ZebraTriggerCallback = FutureOr<void> Function();

class Zebra {
  static const MethodChannel _platform = MethodChannel("sdk_function_channel");
  static const String _deviceType = 'Zebra';
  static const String _methodSetDeviceType = 'setDeviceType';
  static const String _methodConnectRfid = 'connectRFID';
  static const String _methodStartInventory = 'startInventory';
  static const String _methodStopInventory = 'stopInventory';
  static const String _methodSetScanEnabled = 'setScanEnabled';
  static const String _methodPlaySound = 'playSound';
  static const String _methodTagScanned = 'onTagScanned';
  static const String _methodTriggerPressed = 'onTriggerPressed';
  static const String _methodTriggerReleased = 'onTriggerReleased';
  static const String _methodTriggerBlocked = 'onTriggerBlocked';
  static const String _unsupportedMessage =
      'RFID รองรับเฉพาะเครื่อง Zebra เท่านั้น';

  static bool _isDeviceSelected = false;
  static bool _isMethodHandlerRegistered = false;
  static String _lastErrorMessage = '';
  static ZebraTagScannedCallback? _onTagScanned;
  static ZebraTriggerCallback? _onTriggerPressed;
  static ZebraTriggerCallback? _onTriggerReleased;
  static ZebraTriggerCallback? _onTriggerBlocked;

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

      return manufacturer.contains('zebra') ||
          brand.contains('zebra') ||
          model.contains('zebra');
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

  static Future<void> _ensureDevice() async {
    await _ensureSupportedDevice();

    if (_isDeviceSelected) {
      return;
    }

    await _invoke<String>(_methodSetDeviceType, {'setDeviceType': _deviceType});
    _isDeviceSelected = true;
  }

  static Future<void> _ensureMethodHandler() async {
    if (_isMethodHandlerRegistered) {
      return;
    }

    _platform.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case _methodTagScanned:
          Map<String, dynamic> arguments = <String, dynamic>{};
          if (call.arguments is Map) {
            arguments = Map<String, dynamic>.from(call.arguments as Map);
          }

          final String epc = (arguments['epc'] as String? ?? '').toUpperCase();
          final String rssi = arguments['rssi'] as String? ?? '';
          await _onTagScanned?.call(epc, rssi);
          return null;
        case _methodTriggerPressed:
          await _onTriggerPressed?.call();
          return null;
        case _methodTriggerReleased:
          await _onTriggerReleased?.call();
          return null;
        case _methodTriggerBlocked:
          await _onTriggerBlocked?.call();
          return null;
        default:
          return null;
      }
    });

    _isMethodHandlerRegistered = true;
  }

  static Future<bool> setDevice() async {
    _lastErrorMessage = '';
    try {
      await _ensureDevice();
      debugPrint("Device set to Zebra");
      return true;
    } on PlatformException catch (e) {
      _lastErrorMessage = e.message ?? 'Unsupported Zebra device';
      debugPrint("Error setting device: $_lastErrorMessage");
      return false;
    } catch (e) {
      _lastErrorMessage = e.toString();
      debugPrint("Error setting device: $e");
      return false;
    }
  }

  /// Connects to the Zebra RFID reader. Returns `true` on success.
  /// UI feedback belongs in presentation, not here.
  Future<bool> initialize() async {
    try {
      await _ensureDevice();
      await _ensureMethodHandler();
      await _invoke<dynamic>(_methodConnectRfid);
      return true;
    } catch (e) {
      debugPrint('Error initializing: $e');
      return false;
    }
  }

  Future startInventory() async {
    try {
      await _ensureDevice();
      await _invoke<dynamic>(_methodStartInventory);
    } catch (e) {
      debugPrint("Error starting inventory: $e");
    }
  }

  Future stopInventory() async {
    try {
      await _ensureDevice();
      await _invoke<dynamic>(_methodStopInventory);
    } catch (e) {
      debugPrint("Error stopping inventory: $e");
    }
  }

  static Future playSound() async {
    await _invoke<dynamic>(_methodPlaySound);
  }

  static Future<String> setTagScannedListener(
    ZebraTagScannedCallback onTagScanned,
  ) async {
    try {
      await _ensureDevice();
      _onTagScanned = onTagScanned;
      await _ensureMethodHandler();
    } catch (e) {
      debugPrint('Error Scanned: $e');
      return 'Error';
    }

    return "Listening";
  }

  static Future<String> setTriggerListener({
    ZebraTriggerCallback? onPressed,
    ZebraTriggerCallback? onReleased,
    ZebraTriggerCallback? onBlocked,
  }) async {
    try {
      await _ensureDevice();
      _onTriggerPressed = onPressed;
      _onTriggerReleased = onReleased;
      _onTriggerBlocked = onBlocked;
      await _ensureMethodHandler();
    } catch (e) {
      debugPrint('Error trigger listener: $e');
      return 'Error';
    }

    return "Listening";
  }

  static void clearTagScannedListener() {
    _onTagScanned = null;
  }

  static void clearTriggerListener() {
    _onTriggerPressed = null;
    _onTriggerReleased = null;
    _onTriggerBlocked = null;
  }

  static Future<void> setScanEnabled(bool isEnabled) async {
    try {
      await _ensureDevice();
      await _invoke<dynamic>(_methodSetScanEnabled, {'isEnabled': isEnabled});
    } catch (e) {
      debugPrint('Error setting scan enabled: $e');
    }
  }

  static Future<void> release() async {
    _isDeviceSelected = false;
    _isMethodHandlerRegistered = false;
    _lastErrorMessage = '';
    clearTagScannedListener();
    clearTriggerListener();
    _platform.setMethodCallHandler(null);
  }
}
