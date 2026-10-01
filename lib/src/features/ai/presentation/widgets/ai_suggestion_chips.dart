import 'package:bs_mobile/src/core/localization/locale_extension.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AiSuggestionChips extends StatelessWidget {
  const AiSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.isLoading = false,
    this.isHidden = false,
    this.onHide,
    this.onShow,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final bool isLoading;
  final bool isHidden;
  final VoidCallback? onHide;
  final VoidCallback? onShow;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    if (isHidden) {
      if (suggestions.isEmpty) return const SizedBox.shrink();

      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onShow,
          icon: Icon(
            Icons.tips_and_updates_outlined,
            size: 16,
            color: cs.primary,
          ),
          label: AppText(
            context.tr(
              'mobile.ai_show_suggestions',
              fallback: 'แสดงคำถามแนะนำ',
            ),
            style: TextStyle(fontSize: 12, color: cs.primary),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 8),
            AppText(
              context.tr(
                'mobile.ai_suggestions_loading',
                fallback: 'กำลังโหลดคำถามแนะนำ...',
              ),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                context.tr(
                  'mobile.ai_suggestions_title',
                  fallback: 'คำถามแนะนำ',
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            if (onHide != null)
              IconButton(
                onPressed: onHide,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                tooltip: context.tr(
                  'mobile.ai_hide_suggestions',
                  fallback: 'ซ่อนคำถามแนะนำ',
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return _SuggestionChip(
              text: suggestion,
              onTap: () => onSuggestionTap(suggestion),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: AppText(
            text,
            style: TextStyle(fontSize: 12, height: 1.35, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
