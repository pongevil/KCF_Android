import 'package:flutter/material.dart';

/// Opens the template's standard keyboard-aware modal bottom sheet.
///
/// The modal route owns keyboard insets and system safe areas so individual
/// sheets do not need to repeat that layout code. Tapping empty space or
/// dragging scrollable content dismisses the current keyboard focus.
Future<T?> showCustomModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
  Color? barrierColor,
  bool requestFocus = true,
  Duration insetAnimationDuration = const Duration(milliseconds: 180),
  Curve insetAnimationCurve = Curves.easeOut,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    barrierColor: barrierColor,
    requestFocus: requestFocus,
    builder: (modalContext) => AnimatedPadding(
      duration: insetAnimationDuration,
      curve: insetAnimationCurve,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(modalContext).bottom,
      ),
      child: SafeArea(
        top: false,
        child: _DismissKeyboardRegion(child: builder(modalContext)),
      ),
    ),
  );
}

class _DismissKeyboardRegion extends StatelessWidget {
  const _DismissKeyboardRegion({required this.child});

  final Widget child;

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null) {
            _dismissKeyboard();
          }
          return false;
        },
        child: child,
      ),
    );
  }
}
