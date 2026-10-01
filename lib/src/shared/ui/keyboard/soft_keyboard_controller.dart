import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ตัวควบคุมกลางสำหรับเปิด/ปิด soft keyboard
///
/// วิธีการ: **ไม่** ตัด input connection (ไม่ใช้ TextInputType.none / custom
/// TextInputControl) เพราะ scanner บางรุ่น commit ข้อความผ่าน IME connection
/// ถ้าตัด connection จะสแกนไม่ติด. แทนที่จะตัด เราปล่อยให้ IME session เริ่ม
/// ตามปกติ (commit ได้) แล้ว "ซ่อนหน้าต่าง keyboard" ทันทีที่มันเด้งขึ้นมา ผ่าน
/// `TextInput.hide` + ฟัง [didChangeMetrics]
///
/// - `enabled == true`  => keyboard แสดงได้ตามปกติ
/// - `enabled == false` => ซ่อน keyboard ทุกครั้งที่มันพยายามเด้ง (การสแกนยังทำงาน)
///
/// ช่องที่ต้องใช้ keyboard เสมอ (เช่น qty) เรียก [pushForceKeyboard] ตอน focus
/// และ [popForceKeyboard] ตอนเสีย focus เพื่อบังคับให้ keyboard เด้งชั่วคราว
///
/// ค่าเป็น global in-memory จำข้ามหน้าในเซสชันเดียว จนกว่าจะกดสลับ
class SoftKeyboardController with WidgetsBindingObserver {
  SoftKeyboardController._();

  static final SoftKeyboardController instance = SoftKeyboardController._();

  /// เปิด/ปิด debug log (default = เปิดใน debug build)
  static bool debugLogging = kDebugMode;

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  int _forceKeyboardCount = 0;
  bool _observerAdded = false;
  bool _debugKeyHandlerAdded = false;

  bool get _shouldSuppress => !enabled.value && _forceKeyboardCount == 0;

  void _ensureObserver() {
    if (_observerAdded) {
      return;
    }
    _observerAdded = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void toggle() => _set(!enabled.value);

  void enable() => _set(true);

  void disable() => _set(false);

  void _set(bool value) {
    if (enabled.value == value) {
      return;
    }
    enabled.value = value;
    _ensureObserver();
    if (_shouldSuppress) {
      _hideKeyboard();
    } else {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  /// บังคับให้ keyboard เด้ง (ใช้ตอน field ที่ต้องการ keyboard เสมอได้ focus)
  void pushForceKeyboard() {
    _forceKeyboardCount++;
    _ensureObserver();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  /// ยกเลิกการบังคับ keyboard (ใช้ตอน field นั้นเสีย focus)
  void popForceKeyboard() {
    if (_forceKeyboardCount > 0) {
      _forceKeyboardCount--;
    }
    if (_shouldSuppress) {
      _hideKeyboard();
    }
  }

  void _hideKeyboard() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  void didChangeMetrics() {
    if (!_shouldSuppress) {
      return;
    }
    // keyboard อาจเพิ่งเด้งขึ้น (เช่นตอน scanner ยิงค่าผ่าน IME) -> ซ่อนทันที
    // โดย IME session ยังทำงาน (commit ค่าได้ตามปกติ) แค่หน้าต่างถูกซ่อน
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldSuppress) {
        _hideKeyboard();
      }
    });
  }

  /// ติดตั้ง handler ที่ log ทุก hardware key event (ใช้ debug scanner แบบ HID)
  void enableDebugKeyLogging() {
    if (_debugKeyHandlerAdded) {
      return;
    }
    HardwareKeyboard.instance.addHandler(_debugKeyHandler);
    _debugKeyHandlerAdded = true;
  }

  bool _debugKeyHandler(KeyEvent event) {
    if (debugLogging) {
      debugPrint(
        '[SoftKb][key] ${event.runtimeType} '
        'logical=${event.logicalKey.keyLabel} '
        'char=${event.character} '
        'kbEnabled=${enabled.value}',
      );
    }
    return false;
  }
}

/// ปุ่มสลับซ่อน/แสดง soft keyboard พร้อม icon บอกสถานะ (ใช้บน app bar)
class SoftKeyboardToggleButton extends StatelessWidget {
  final Color? color;

  const SoftKeyboardToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final controller = SoftKeyboardController.instance;
    if (SoftKeyboardController.debugLogging) {
      controller.enableDebugKeyLogging();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: controller.enabled,
      builder: (_, enabled, __) {
        return IconButton(
          tooltip: enabled ? 'ซ่อนคีย์บอร์ด' : 'แสดงคีย์บอร์ด',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          iconSize: 20,
          icon: Icon(
            enabled ? Icons.keyboard : Icons.keyboard_hide,
            color: color,
          ),
          onPressed: controller.toggle,
        );
      },
    );
  }
}
