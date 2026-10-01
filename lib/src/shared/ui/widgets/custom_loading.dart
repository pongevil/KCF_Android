import 'dart:math' as math;

import 'package:bs_mobile/src/core/navigation/app_navigation.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/shared/ui/notification/custom_show_alert.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A global loading overlay with the animated Oga elephant Lottie asset.
///
/// ใช้ [OverlayEntry] แทน [showDialog] จึงไม่ยุ่งกับ Navigator stack —
/// `dismiss()` ปิดเฉพาะ overlay ของตัวเอง ไม่มีปัญหา pop route ผิดหน้า และ
/// ไม่จำเป็นต้องใช้ `Future`/`await`.
///
/// ```dart
/// CustomLoading.show();                       // หมุนแบบ indeterminate
/// CustomLoading.show(text: 'กำลังโหลด...');
///
/// CustomLoading.showProgress(text: 'ดาวน์โหลด', autoDismiss: true);
/// CustomLoading.setProgress(0.4);             // 0.0 - 1.0
/// CustomLoading.setProgress(1.0);             // ถึง 100% + autoDismiss → ปิดเอง
///
/// CustomLoading.dismiss();
/// CustomLoading.dismiss(
///   messageText: 'บันทึกสำเร็จ',
///   alertType: CustomAlertType.success,
/// );
/// ```
class CustomLoading {
  CustomLoading._();

  /// The Lottie mascot shown in the loading overlay.
  static const lottieAssetPath = 'assets/lottie/elephant-biped-loading.json';

  static OverlayEntry? _entry;

  /// null = indeterminate (หมุนวน), มีค่า = determinate (0.0 - 1.0)
  static final ValueNotifier<double?> _progress = ValueNotifier<double?>(null);
  static final ValueNotifier<String?> _text = ValueNotifier<String?>(null);

  /// เมื่อ true และ progress ถึง 1.0 จะ [dismiss] อัตโนมัติหลังแสดง 100% สั้น ๆ
  static bool _autoDismiss = false;

  static bool get isShowing => _entry != null;

  /// แสดง loading แบบ indeterminate (ไม่รู้เปอร์เซ็นต์) — ต้องเรียก [dismiss] เองเมื่องานเสร็จ
  static void show({String? text}) {
    _autoDismiss = false;
    _progress.value = null;
    _text.value = text;
    _insert();
  }

  /// แสดง loading แบบ progress (ระบุเปอร์เซ็นต์ได้)
  ///
  /// [autoDismiss] — เมื่อ progress ถึง 1.0 (ผ่าน [setProgress] หรือค่าเริ่มต้น)
  /// จะปิด overlay เอง ไม่ต้องเรียก [dismiss]
  static void showProgress({
    double progress = 0,
    String? text,
    bool autoDismiss = false,
  }) {
    _autoDismiss = autoDismiss;
    _text.value = text;
    final clamped = progress.clamp(0.0, 1.0);
    _progress.value = clamped;
    _insert();
    _maybeAutoDismiss(clamped);
  }

  /// อัปเดตค่า progress ระหว่างทำงาน (ถ้ายังไม่ได้ show จะ show ให้เลย)
  static void setProgress(double progress, {String? text}) {
    final clamped = progress.clamp(0.0, 1.0);
    _progress.value = clamped;
    if (text != null) _text.value = text;
    _insert();
    _maybeAutoDismiss(clamped);
  }

  /// ปิด loading — ถ้าระบุ [messageText] และ [alertType] จะแสดง [CustomShowAlert] ต่อทันที
  static void dismiss({
    String? messageText,
    CustomAlertType? alertType,
    Duration? alertDuration,
  }) {
    _entry?.remove();
    _entry = null;
    _autoDismiss = false;

    if (messageText != null && alertType != null) {
      CustomShowAlert.show(messageText, alertType, duration: alertDuration);
    }
  }

  static void _maybeAutoDismiss(double progress) {
    if (!_autoDismiss || progress < 1.0) return;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!_autoDismiss || !isShowing) return;
      if ((_progress.value ?? 0) >= 1.0) dismiss();
    });
  }

  static void _insert() {
    if (_entry != null) return; // กำลังแสดงอยู่ — notifier จะอัปเดต UI เอง
    final overlay = appNavigation.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _entry = OverlayEntry(
      builder: (_) => _RobotLoadingView(progress: _progress, text: _text),
    );
    overlay.insert(_entry!);
  }
}

class _RobotLoadingView extends StatefulWidget {
  final ValueListenable<double?> progress;
  final ValueListenable<String?> text;

  const _RobotLoadingView({required this.progress, required this.text});

  @override
  State<_RobotLoadingView> createState() => _RobotLoadingViewState();
}

class _RobotLoadingViewState extends State<_RobotLoadingView> {
  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final lottieWidth = math.min(screenWidth * 0.9, 420.0);

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: ValueListenableBuilder<double?>(
          valueListenable: widget.progress,
          builder: (_, progress, _) {
            final isProgress = progress != null;
            final cardWidth = isProgress
                ? math.min(lottieWidth + 32, screenWidth)
                : lottieWidth;
            final contentWidth = isProgress ? cardWidth - 32 : lottieWidth;
            final lottieHeight = contentWidth * 0.75;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: cardWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: isProgress ? 16 : 0,
                  vertical: isProgress ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  color: isProgress ? cs.surface : Colors.transparent,
                  borderRadius: isProgress
                      ? BorderRadius.circular(20)
                      : BorderRadius.zero,
                  boxShadow: isProgress
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: contentWidth,
                      height: lottieHeight,
                      child: Lottie.asset(
                        CustomLoading.lottieAssetPath,
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    if (isProgress) ...[
                      const SizedBox(height: 8),
                      _ProgressContent(
                        width: math.min(contentWidth, 320.0),
                        progress: progress,
                        text: widget.text,
                        colorScheme: cs,
                      ),
                    ] else
                      ValueListenableBuilder<String?>(
                        valueListenable: widget.text,
                        builder: (_, text, _) {
                          if (text == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: AppText(
                              text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final double width;
  final double progress;
  final ValueListenable<String?> text;
  final ColorScheme colorScheme;

  const _ProgressContent({
    required this.width,
    required this.progress,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'ความคืบหน้า',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppText(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: text,
            builder: (_, message, _) {
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: AppText(
                  message ?? 'กรุณารอสักครู่',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
