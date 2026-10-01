import 'package:bs_mobile/src/shared/to_display_show.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class PickDateWidget extends StatelessWidget {
  const PickDateWidget({
    super.key,
    required this.onChanged,
    this.selectedDate,
    this.onCleared,
    this.labelText = 'Select Date',
    this.firstDate,
    this.lastDate,
    this.prefixIcon = Icons.calendar_month_outlined,
    this.labelFontSize = 26,
    this.valueFontSize = 22,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.enabled = true,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onChanged;
  final ValueChanged<DateTime>? onCleared;
  final String labelText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData prefixIcon;
  final double labelFontSize;
  final double valueFontSize;
  final BorderRadius borderRadius;
  final bool enabled;

  static Future<DateTime> pickDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final minDate = firstDate ?? DateTime(now.year - 5, now.month, now.day);
    final maxDate = lastDate ?? DateTime(now.year + 5, now.month, now.day);
    final safeInitialDate = _clampDate(initialDate ?? now, minDate, maxDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: minDate,
      lastDate: maxDate,
    );

    return picked ?? now;
  }

  static DateTime _clampDate(
    DateTime value,
    DateTime minDate,
    DateTime maxDate,
  ) {
    if (value.isBefore(minDate)) {
      return minDate;
    }

    if (value.isAfter(maxDate)) {
      return maxDate;
    }

    return value;
  }

  Future<void> _handleTap(BuildContext context) async {
    if (!enabled) {
      return;
    }

    final pickedDate = await pickDate(
      context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (!context.mounted) {
      return;
    }

    onChanged(pickedDate);
  }

  void _handleClear() {
    final fallbackDate = DateUtils.dateOnly(DateTime.now());

    if (onCleared != null) {
      onCleared!(fallbackDate);
      return;
    }

    onChanged(fallbackDate);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayDate = selectedDate ?? DateUtils.dateOnly(DateTime.now());

    return InkWell(
      borderRadius: borderRadius,
      onTap: enabled ? () => _handleTap(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: labelFontSize,
          ),
          filled: true,
          fillColor: cs.surface,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: selectedDate == null
              ? null
              : IconButton(
                  onPressed: _handleClear,
                  icon: const Icon(Icons.clear),
                ),
          border: OutlineInputBorder(borderRadius: borderRadius),
        ),
        child: AppText(
          ToDisplayShow.toDisplayDate(displayDate),
          fontSize: valueFontSize,
          color: selectedDate == null ? cs.onSurfaceVariant : cs.onSurface,
        ),
      ),
    );
  }
}
