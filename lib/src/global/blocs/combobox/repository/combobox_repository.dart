import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/global/blocs/combobox/models/combobox_api_model.dart';

class ComboboxRepository {
  ComboboxRepository(this._client);

  final ApiClient _client;

  Future<ComboboxResponse> getCombobox(String group_name) async {
    try {
      final response = await _client.get(
        'Mobile/Combobox/GetCombobox?group_name=$group_name',
      );
      return ComboboxResponse.fromJson(response.data);
    } catch (e) {
      return ComboboxResponse(
        isSuccess: false,
        messageCode: 'ERROR',
        message: e.toString(),
      );
    }
  }
}
