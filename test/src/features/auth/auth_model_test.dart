import 'package:bs_mobile/src/features/auth/models/auth_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login request includes the WM3 application id', () {
    final request = AuthLoginRequest(
      applicationId: 'wm3-app-id',
      applicationLicense: 'license',
      username: 'user',
      password: 'password',
      platform: 'MOBILE',
    );

    expect(request.toJson()['app_id'], 'wm3-app-id');
  });

  test('parses the production legacy login response', () {
    final response = AuthLoginResponse.fromJson({
      'is_success': true,
      'result_code': '0',
      'result_msg': 'Login success',
      'user': {'user_id': '1'},
    });

    expect(response.messageCode, '0');
    expect(response.messageText, 'Login success');
    expect(response.data.accessToken, isEmpty);
  });
}
