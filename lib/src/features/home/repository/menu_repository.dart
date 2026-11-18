import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_endpoints.dart';
import 'package:bs_mobile/src/features/home/models/menu_response_model.dart';

class MenuRepository {
  final ApiClient _client;

  MenuRepository(this._client);

  Future<MenuResponse> fetchMenu() async {
    try {
      final response = await _client.post(
        ApiEndpoints.securityMenu,
        data: const {'platform': 'MOBILE'},
      );
      final body = response.data;
      if (body is List) {
        return MenuResponse(
          data: body
              .whereType<Map>()
              .map((item) => MenuData.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false),
          messageCode: '0',
          messageText: 'Success',
        );
      }
      if (body is Map) {
        return MenuResponse.fromJson(Map<String, dynamic>.from(body));
      }
      throw StateError('GetMenu returned an unsupported payload');
    } catch (e) {
      return MenuResponse(messageCode: '1', messageText: e.toString());
    }
  }
}
