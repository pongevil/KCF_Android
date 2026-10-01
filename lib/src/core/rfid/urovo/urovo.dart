import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Urovo {
  static const MethodChannel _platform = MethodChannel("sdk_function_channel");

  static const String _deviceType = 'Urovo';
  static const String _methodSetDeviceType = 'setDeviceType';
  static const String _methodInitScanner = 'urovoinitScanner';
  static const String _methodStartInventory = 'urovostartInventory';
  static const String _methodStopInventory = 'urovostopInventory';
  static const String _methodOpenScanner = 'urovoOpenScanner';
  static const String _methodCloseScanner = 'urovoCloseScanner';
  static const String _methodGetPower = 'urovoGetPower';
  static const String _methodSetPower = 'urovoSetPower';
  static const String _methodRelease = 'urovoRelease';
  static const String _methodTagScanned = 'urovoonTagScanned';
  static const String _methodTriggerKey = 'urovoonTriggerKey';
  static const int _defaultPower = 33;
  static const String _unsupportedMessage =
      'RFID รองรับเฉพาะเครื่อง Urovo เท่านั้น';
  static const String _methodPlayBeep = 'playBeep';

  static bool _isDeviceSelected = false;
  static bool _isScannerInitialized = false;
  static bool _isMethodHandlerSet = false;
  static Future<void>? _pendingInitialization;
  static String _lastErrorMessage = '';
  static void Function(String epc, String rssi, String tid)? _onTagScanned;
  static void Function(int keyCode, bool isKeyDown)? _onTriggerKey;
  static final RegExp _hexPattern = RegExp(r'^[0-9A-Fa-f]+$');
  static final RegExp _decodedTextPattern = RegExp(r'^[A-Za-z0-9._-]+$');

  static String get lastErrorMessage => _lastErrorMessage;

  static Future<T?> _invoke<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) {
    return _platform.invokeMethod<T>(method, arguments);
  }

  static String _normalizeEpc(String epc) {
    final String trimmed = epc.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final String? decoded = _tryDecodeHexAscii(trimmed);
    return decoded ?? trimmed;
  }

  static String? _tryDecodeHexAscii(String value) {
    if (value.length.isOdd || !_hexPattern.hasMatch(value)) {
      return null;
    }

    try {
      final List<int> bytes = <int>[];
      for (int index = 0; index < value.length; index += 2) {
        bytes.add(int.parse(value.substring(index, index + 2), radix: 16));
      }

      final List<int> asciiBytes = bytes
          .where((int byte) => byte != 0)
          .toList();
      if (asciiBytes.isEmpty) {
        return null;
      }

      final String decoded = ascii
          .decode(asciiBytes, allowInvalid: false)
          .trim();
      if (decoded.isEmpty) {
        return null;
      }

      final bool isPrintableAscii = decoded.runes.every(
        (int rune) => rune >= 32 && rune <= 126,
      );

      if (!isPrintableAscii || !_decodedTextPattern.hasMatch(decoded)) {
        return null;
      }

      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _ensureMethodCallHandler() async {
    if (_isMethodHandlerSet) {
      return;
    }

    _platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == _methodTagScanned) {
        final Map<dynamic, dynamic> arguments =
            (call.arguments is Map<dynamic, dynamic>)
            ? call.arguments as Map<dynamic, dynamic>
            : <dynamic, dynamic>{};

        final String epc = _normalizeEpc((arguments['epc'] ?? '').toString());
        final String rssi = (arguments['rssi'] ?? '').toString();
        final String tid = (arguments['tid'] ?? '').toString();

        if (epc.isNotEmpty && _onTagScanned != null) {
          _onTagScanned!(epc, rssi, tid);
        }
        return null;
      }

      if (call.method == _methodTriggerKey) {
        final Map<dynamic, dynamic> arguments =
            (call.arguments is Map<dynamic, dynamic>)
            ? call.arguments as Map<dynamic, dynamic>
            : <dynamic, dynamic>{};

        final int keyCode = arguments['keyCode'] is int
            ? arguments['keyCode'] as int
            : int.tryParse(arguments['keyCode']?.toString() ?? '') ?? -1;

        final String action = (arguments['action'] ?? '').toString();
        final bool isKeyDown = action == 'down';

        if (keyCode != -1 && _onTriggerKey != null) {
          _onTriggerKey!(keyCode, isKeyDown);
        }
        return null;
      }

      return null;
    });

    _isMethodHandlerSet = true;
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

      return manufacturer.contains('urovo') ||
          brand.contains('urovo') ||
          model.contains('urovo');
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

  static Future<String> _selectDevice() async {
    await _ensureSupportedDevice();

    if (_isDeviceSelected) {
      return 'Connected RFID Urovo';
    }

    final result = await _invoke<String>(_methodSetDeviceType, {
      'setDeviceType': _deviceType,
    });
    _isDeviceSelected = true;
    return result ?? 'Connected RFID Urovo';
  }

  static Future<void> _ensureScannerInitialized() async {
    await _selectDevice();
    if (_isScannerInitialized) {
      return;
    }

    final Future<void> activeInitialization = _pendingInitialization ??=
        () async {
          await _invoke<dynamic>(_methodInitScanner);
          _isScannerInitialized = true;
        }();

    try {
      await activeInitialization;
    } finally {
      if (identical(_pendingInitialization, activeInitialization)) {
        _pendingInitialization = null;
      }
    }
  }

  static void _resetInitializationState() {
    _isDeviceSelected = false;
    _isScannerInitialized = false;
    _pendingInitialization = null;
  }

  static bool _isRecoverableScannerError(Object error) {
    return error is PlatformException &&
        (error.code == 'RFID_NOT_READY' || error.code == 'SCANNER_NOT_READY');
  }

  static Future<T?> _invokeWithScannerRecovery<T>(
    String method, {
    Map<String, dynamic>? arguments,
  }) async {
    try {
      await _ensureScannerInitialized();
      return await _invoke<T>(method, arguments);
    } on PlatformException catch (e) {
      if (!_isRecoverableScannerError(e)) {
        rethrow;
      }

      _lastErrorMessage = e.message ?? 'RFID session is not ready';
      _resetInitializationState();
      await _ensureScannerInitialized();
      return await _invoke<T>(method, arguments);
    }
  }

  /// Re-initialises the RFID scanner without any loading UI.
  /// Resets the initialisation flag so the native side is re-woken on every
  /// scan trigger, guarding against the case where the native RFID service
  /// silently died between uses.
  static Future<bool> silentReinit() async {
    try {
      _isScannerInitialized =
          false; // force re-init on next _ensureScannerInitialized call
      await _ensureScannerInitialized();
      return true;
    } catch (e) {
      debugPrint('Urovo silentReinit error: $e');
      return false;
    }
  }

  /// Initializes the RFID scanner. Returns `'Success'` or `'Error'`.
  /// UI loading/alerts belong in presentation (page / BLoC), not here.
  static Future<String> initRfid() async {
    _lastErrorMessage = '';
    try {
      await _ensureScannerInitialized();
      return 'Success';
    } on MissingPluginException {
      _lastErrorMessage = 'RFID plugin is not available';
      return 'Error';
    } on PlatformException catch (e) {
      _lastErrorMessage = e.message ?? 'RFID initialization failed';
      debugPrint('Urovo initRfid platform error: $_lastErrorMessage');
      return 'Error';
    } catch (e) {
      _lastErrorMessage = 'RFID initialization failed';
      debugPrint('Urovo initRfid error: $e');
      return 'Error';
    }
  }

  static Future<String> setTagScannedListener(
    Function(String epc, String rssi, String tid) onTagScanned,
  ) async {
    try {
      _onTagScanned = onTagScanned;
      await _ensureMethodCallHandler();
    } catch (e) {
      debugPrint('Error Scanned: $e');
      return 'Error';
    }

    return "Listening";
  }

  static Future<String> setTriggerKeyListener(
    Function(int keyCode, bool isKeyDown) onTriggerKey,
  ) async {
    try {
      _onTriggerKey = onTriggerKey;
      await _ensureMethodCallHandler();
    } catch (e) {
      debugPrint('Error Trigger Listener: $e');
      return 'Error';
    }

    return 'Listening';
  }

  static Future<dynamic> scan(bool status) async {
    return status ? startInventory() : stopInventory();
  }

  static Future<dynamic> scanner(bool status) async {
    return status ? openScanner() : closeScanner();
  }

  static Future<dynamic> startInventory() async {
    try {
      return await _invokeWithScannerRecovery<dynamic>(_methodStartInventory);
    } catch (e) {
      debugPrint('Urovo startInventory error: $e');
      return 'Error';
    }
  }

  static Future<dynamic> stopInventory() async {
    try {
      return await _invokeWithScannerRecovery<dynamic>(_methodStopInventory);
    } catch (e) {
      debugPrint('Urovo stopInventory error: $e');
      return 'Error';
    }
  }

  static Future<dynamic> openScanner() async {
    try {
      return await _invokeWithScannerRecovery<dynamic>(_methodOpenScanner);
    } catch (e) {
      debugPrint('Urovo openScanner error: $e');
      return 'Error';
    }
  }

  static Future<dynamic> closeScanner() async {
    try {
      return await _invokeWithScannerRecovery<dynamic>(_methodCloseScanner);
    } catch (e) {
      debugPrint('Urovo closeScanner error: $e');
      return 'Error';
    }
  }

  static Future<void> checkConnection() async {
    try {
      await _ensureScannerInitialized();
      final power = await getPower();
      if (power == null || power == -1) {
        await setPower(_defaultPower);
      }
    } catch (e) {
      debugPrint('Urovo checkConnection error: $e');
    }
  }

  static Future<int?> getPower() async {
    try {
      final dynamic result = await _invokeWithScannerRecovery<dynamic>(
        _methodGetPower,
      );
      debugPrint("result: $result");
      if (result is int) {
        return result;
      }
      return int.tryParse(result?.toString() ?? '');
    } catch (e) {
      debugPrint('Urovo getPower error: $e');
      return null;
    }
  }

  static Future<dynamic> playBeep() async {
    try {
      await _invoke<dynamic>(_methodPlayBeep);
    } catch (e) {
      debugPrint('Urovo playBeep error: $e');
      return 'Error';
    }
  }

  static Future<dynamic> setPower(int setpower) async {
    try {
      debugPrint("Power of setpower: $setpower");
      final dynamic result = await _invokeWithScannerRecovery<dynamic>(
        _methodSetPower,
        arguments: {"power": setpower},
      );
      return result;
    } catch (e) {
      debugPrint('$e');
      return 'Error';
    }
  }

  static Future<void> release() async {
    try {
      await _invoke<dynamic>(_methodRelease);
    } catch (e) {
      debugPrint('$e');
    } finally {
      _resetInitializationState();
    }
  }
}
