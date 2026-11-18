import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_endpoints.dart';
import 'package:bs_mobile/src/features/home/repository/menu_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('loads production menu from WM3 Security without mock assets', () async {
    final client = _MockApiClient();
    final repository = MenuRepository(client);
    when(
      () => client.post(
        ApiEndpoints.securityMenu,
        data: const {'platform': 'MOBILE'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.securityMenu),
        data: [
          {
            'menu_id': 1,
            'menu_name': 'Goods Receive Weight Scale',
            'menu_path': '/goods_receive_weight_scale',
            'is_view': 'Y',
          },
        ],
      ),
    );

    final result = await repository.fetchMenu();

    expect(result.messageCode, '0');
    expect(result.data?.single.menuPath, '/goods_receive_weight_scale');
    verify(
      () => client.post(
        ApiEndpoints.securityMenu,
        data: const {'platform': 'MOBILE'},
      ),
    ).called(1);
  });
}
