import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses configured gateway by default in production builds', () {
    expect(ApiClient.isRunLocalhost, isFalse);
  });

  test('routes login through the configured server', () {
    expect(ApiClient.isGatewayOnlyPath('WM3_Security/Secure/Login'), isTrue);
  });

  test('routes WM3_API_Mobile through the configured server', () {
    expect(
      ApiClient.isGatewayOnlyPath(
        'WM3_API_Mobile/api/WeightScaleMapping/GetMappings',
      ),
      isTrue,
    );
  });

  test('production endpoints include their IIS application paths', () {
    expect(ApiEndpoints.securityLogin, startsWith('WM3_Security/'));
    expect(ApiEndpoints.securityMenu, 'WM3_Security/Secure/GetMenu');
    expect(ApiEndpoints.mobileConfigDecimal, startsWith('WM3_API_Mobile/'));
  });
}
