import 'package:bs_mobile/src/core/network/api_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ApiErrorMapper();

  group('ApiErrorMapper', () {
    test('fromStatusCode returns Unauthorized for 401', () {
      expect(mapper.fromStatusCode(401, null), 'Unauthorized');
    });

    test('extractMessage reads message_text from map', () {
      expect(
        mapper.extractMessage({'message_text': 'Invalid request'}),
        'Invalid request',
      );
    });

    test('fromStatusCode extracts 404 message', () {
      expect(mapper.fromStatusCode(404, {'message': 'Not found'}), 'Not found');
    });
  });
}
