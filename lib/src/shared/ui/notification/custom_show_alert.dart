import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum CustomAlertType { warning, error, success, info }

class CustomShowAlert {
  /// ระยะเวลาแสดง toast เริ่มต้น (ทุกประเภท)
  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    String message,
    CustomAlertType type, {
    Duration? duration,
  }) => _show(message, type, duration: duration ?? defaultDuration);

  static void showWarning(String message, {Duration? duration}) =>
      _show(message, CustomAlertType.warning, duration: duration);

  static void showError(String message, {Duration? duration}) =>
      _show(message, CustomAlertType.error, duration: duration);

  static void showSuccess(String message, {Duration? duration}) =>
      _show(message, CustomAlertType.success, duration: duration);

  /// แจ้งข้อมูลทั่วไป — ค่าเริ่มต้นแสดง 3 วินาที (ปรับด้วย [duration])
  static void showInfo(String message, {Duration? duration}) =>
      _show(message, CustomAlertType.info, duration: duration);

  static void _show(
    String message,
    CustomAlertType type, {
    Duration? duration,
  }) {
    BotToast.showCustomNotification(
      toastBuilder: (_) => _ThemedAlert(message: message, type: type),
      duration: duration ?? defaultDuration,
      wrapAnimation: type == CustomAlertType.warning
          ? (controller, cancel, child) =>
                FadeTransition(opacity: controller, child: child)
          : null,
    );
  }
}

class _ThemedAlert extends StatelessWidget {
  const _ThemedAlert({required this.message, required this.type});

  final String message;
  final CustomAlertType type;

  @override
  Widget build(BuildContext context) {
    final app = context.appTheme;
    final cs = context.colorScheme;

    final (Color accent, IconData icon) = switch (type) {
      CustomAlertType.warning => (app.warning, Icons.warning_rounded),
      CustomAlertType.error => (app.error, Icons.error_outline_rounded),
      CustomAlertType.success => (
        app.success,
        Icons.check_circle_outline_rounded,
      ),
      CustomAlertType.info => (app.info, Icons.info_outline_rounded),
    };

    final width = MediaQuery.of(context).size.width * 0.92;
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(color: accent, width: 6),
              const SizedBox(width: 16),
              Icon(icon, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 4,
                  ),
                  child: AppText(
                    message,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                onPressed: () => BotToast.cleanAll(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
