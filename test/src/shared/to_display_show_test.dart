import 'package:bs_mobile/src/shared/to_display_show.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toFileNameDate uses storage-safe yyyyMMdd', () {
    final date = DateTime(2026, 7, 21);
    expect(ToDisplayShow.toFileNameDate(date), '20260721');
    expect(ToDisplayShow.toFileNameDate(date).contains('/'), isFalse);
  });

  test('toDisplayDate keeps dd/MM/yyyy for UI', () {
    final date = DateTime(2026, 7, 21);
    expect(ToDisplayShow.toDisplayDate(date), '21/07/2026');
  });
}
