import 'package:flutter/foundation.dart';

/// Colored console logging utility for API debugging.
class DebugLogColors {
  static const _reset = '\x1B[0m';
  static const _yellow = '\x1B[33m';
  static const _green = '\x1B[32m';
  static const _red = '\x1B[31m';
  static const _orange = '\x1B[33m';

  static void request(String message) {
    if (kDebugMode) {
      print('$_yellow[REQUEST] $message$_reset');
    }
  }

  static void response(String message) {
    if (kDebugMode) {
      print('$_green[RESPONSE] $message$_reset');
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      print('$_red[ERROR] $message$_reset');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('$_orange[DEBUG] $message$_reset');
    }
  }
}

/// เรียกใช้งานง่ายเหมือน print เช่น debugLog('ข้อความ', type: DebugLogType.request)
enum DebugLogType { request, response, error, debug }

/// เรียกใช้งานง่ายแบบ printDebug("ข้อความ")
void printDebug(String message, [DebugLogType type = DebugLogType.debug]) {
  switch (type) {
    case DebugLogType.request:
      DebugLogColors.request(message);
      break;
    case DebugLogType.response:
      DebugLogColors.response(message);
      break;
    case DebugLogType.error:
      DebugLogColors.error(message);
      break;
    case DebugLogType.debug:
      DebugLogColors.debug(message);
      break;
  }
}
