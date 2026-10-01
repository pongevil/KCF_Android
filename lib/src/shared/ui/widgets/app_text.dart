import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final EdgeInsetsGeometry? padding;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.fontSize = 16,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).colorScheme;
    final textWidget = Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style:
          style ??
          TextStyle(
            color: color ?? appTheme.onSurface,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
    );

    if (padding == null) {
      return textWidget;
    }

    return Padding(padding: padding!, child: textWidget);
  }
}
