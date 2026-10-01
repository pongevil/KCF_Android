import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// กล่อง placeholder สำหรับ skeleton UI — ใช้ร่วมกับ [CustomShimmer]
///
/// ```dart
/// CustomShimmer(
///   child: Column(
///     children: [
///       CustomShimmerBox(height: 22),
///       SizedBox(height: 8),
///       CustomShimmerBox(width: 140, height: 16),
///     ],
///   ),
/// );
/// ```
class CustomShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;

  const CustomShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
    );
  }
}

/// ห่อ child ด้วย shimmer ตามสีจาก [AppThemeExtension]
class CustomShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Color? baseColor;
  final Color? highlightColor;

  const CustomShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final app = Theme.of(context).extension<AppThemeExtension>()!;

    return Shimmer.fromColors(
      baseColor: baseColor ?? app.shimmerBaseColor,
      highlightColor: highlightColor ?? app.shimmerHighlightColor,
      child: child,
    );
  }
}
