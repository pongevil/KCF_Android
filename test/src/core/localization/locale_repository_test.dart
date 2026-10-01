import 'package:bs_mobile/src/core/localization/locale_repository.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Thai fallback messages from the bundled mock asset', () async {
    final repository = LocaleRepository(MockApiClient());

    final messages = await repository.loadFallbackMessages();

    expect(messages['mobile.title'], 'BS Mobile');
    expect(messages['mobile.ai_assistant'], 'ผู้ช่วย AI');
    expect(messages, isNotEmpty);
  });
}
