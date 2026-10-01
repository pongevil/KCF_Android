import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/features/home/models/menu_response_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class MenuRepository {
  final ApiClient _client;
  static const bool _useMockMenu = true;

  MenuRepository(this._client);

  Future<MenuResponse> fetchMenu() async {
    try {
      if (_useMockMenu) {
        final jsonString = await rootBundle.loadString(
          'lib/src/global/mockdata/menu.json',
        );
        return menuResponseFromJson(jsonString);
      }
      final response = await _client.get('menu?platform=MOBILE');
      return MenuResponse.fromJson(response.data);
    } catch (e) {
      return MenuResponse(messageCode: '1', messageText: e.toString());
    }
  }
}
