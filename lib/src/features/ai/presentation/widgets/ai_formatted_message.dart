import 'package:bs_mobile/src/core/ai/models/ai_table_data.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AiFormattedMessage extends StatelessWidget {
  const AiFormattedMessage({
    super.key,
    required this.text,
    this.dataRows = const [],
    this.reportData,
    this.textColor,
  });

  final String text;
  final List<Map<String, dynamic>> dataRows;
  final Map<String, dynamic>? reportData;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = textColor ?? cs.onSurface;
    final structuredTable = normalizePrimaryTableData(dataRows, reportData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildTextBlocks(color),
        if (structuredTable != null && !structuredTable.isEmpty) ...[
          const SizedBox(height: 8),
          _AiResponseTable(data: structuredTable, textColor: color),
        ],
      ],
    );
  }

  List<Widget> _buildTextBlocks(Color color) {
    final normalizedText = text.replaceAll(RegExp(r'\\n|/n'), '\n');
    final lines = normalizedText.split('\n');
    final blocks = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = rawLine.trim();

      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 6));
        continue;
      }

      final tableHeader = parseMarkdownTableRow(line);
      if (tableHeader != null) {
        final tableRows = <List<String>>[tableHeader];
        var cursor = i + 1;

        while (cursor < lines.length) {
          final candidate = lines[cursor].trim();
          if (candidate.isEmpty) {
            cursor++;
            continue;
          }

          final parsed = parseMarkdownTableRow(candidate);
          if (parsed == null) break;
          tableRows.add(parsed);
          cursor++;
        }

        if (tableRows.length >= 2 &&
            isMarkdownSeparatorRow(tableRows[1]) &&
            tableRows.length >= 3) {
          final tableData = AiTableData(
            headerLabels: tableRows[0].map(sanitizeExportText).toList(),
            rows: tableRows
                .skip(2)
                .map((row) => row.map(sanitizeExportText).toList())
                .toList(),
          );

          blocks.add(_AiResponseTable(data: tableData, textColor: color));
          i = cursor - 1;
          continue;
        }
      }

      final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final size = level == 1
            ? 16.0
            : level == 2
            ? 15.0
            : 14.0;
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _inlineText(
              headingMatch.group(2)!,
              color: color,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: size,
                height: 1.4,
                color: color,
              ),
            ),
          ),
        );
        continue;
      }

      final unorderedMatch = RegExp(r'^[-*•]\s+(.+)$').firstMatch(line);
      if (unorderedMatch != null) {
        final items = <String>[];
        var cursor = i;
        while (cursor < lines.length) {
          final match = RegExp(
            r'^[-*•]\s+(.+)$',
          ).firstMatch(lines[cursor].trim());
          if (match == null) break;
          items.add(match.group(1)!);
          cursor++;
        }

        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '• ',
                          style: TextStyle(color: color, height: 1.5),
                        ),
                        Expanded(
                          child: _inlineText(
                            item,
                            color: color,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        i = cursor - 1;
        continue;
      }

      final orderedMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(line);
      if (orderedMatch != null) {
        final items = <String>[];
        var cursor = i;
        var number = 1;
        while (cursor < lines.length) {
          final match = RegExp(
            r'^\d+\.\s+(.+)$',
          ).firstMatch(lines[cursor].trim());
          if (match == null) break;
          items.add('${number++}. ${match.group(1)!}');
          cursor++;
        }

        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => _inlineText(
                      item,
                      color: color,
                      style: TextStyle(fontSize: 13, height: 1.5, color: color),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        i = cursor - 1;
        continue;
      }

      blocks.add(
        _inlineText(
          rawLine,
          color: color,
          style: TextStyle(fontSize: 13, height: 1.45, color: color),
        ),
      );
    }

    return blocks;
  }

  Widget _inlineText(
    String value, {
    required Color color,
    required TextStyle style,
  }) {
    final segments = value.split(RegExp(r'(\*\*.+?\*\*|`[^`]+`)'));

    return RichText(
      text: TextSpan(
        style: style,
        children: segments.map((segment) {
          final boldMatch = RegExp(r'^\*\*(.+?)\*\*$').firstMatch(segment);
          if (boldMatch != null) {
            return TextSpan(
              text: boldMatch.group(1),
              style: style.copyWith(fontWeight: FontWeight.w700),
            );
          }

          final codeMatch = RegExp(r'^`(.+?)`$').firstMatch(segment);
          if (codeMatch != null) {
            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  codeMatch.group(1)!,
                  style: style.copyWith(
                    fontFamily: 'monospace',
                    fontSize: (style.fontSize ?? 13) - 1,
                  ),
                ),
              ),
            );
          }

          return TextSpan(text: segment);
        }).toList(),
      ),
    );
  }
}

class _AiResponseTable extends StatelessWidget {
  const _AiResponseTable({required this.data, required this.textColor});

  final AiTableData data;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        color: cs.surface,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            cs.surfaceContainerHighest.withValues(alpha: 0.65),
          ),
          dataRowMinHeight: 36,
          dataRowMaxHeight: 72,
          columnSpacing: 18,
          horizontalMargin: 12,
          columns: data.headerLabels
              .map(
                (label) => DataColumn(
                  label: AppText(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ),
              )
              .toList(),
          rows: data.rows
              .map(
                (row) => DataRow(
                  cells: List.generate(data.headerLabels.length, (index) {
                    return DataCell(
                      AppText(
                        index < row.length ? row[index] : '',
                        style: TextStyle(fontSize: 12, color: textColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
