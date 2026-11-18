import 'package:bs_mobile/src/core/barcode/barcode_config_validator.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_endpoints.dart';

/// Fetches barcode format configs. Does not own cache — see [BarcodeFormatService].
///
/// API: `GET ConfigApp/GetBarcodeFormat`
/// Response: flat `fields[]` with per-row `tag_function` + shared root `separator`
class BarcodeFormatRepository {
  BarcodeFormatRepository(this._client);

  final ApiClient _client;

  Future<List<BarcodeFormatConfig>> fetchAll() async {
    final response = await _client.get(
      ApiEndpoints.mobileBarcodeFormat,
      showAlert: false,
    );

    final data = response.data;
    if (data is! Map) {
      throw StateError('GetBarcodeFormat returned non-object payload');
    }

    return _configsFromApiResponse(
      BarcodeFormatResponse.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  List<BarcodeFormatConfig> _configsFromApiResponse(
    BarcodeFormatResponse response,
  ) {
    if (!response.isSuccess) {
      printDebug(
        'BarcodeFormat not success: code=${response.messageCode}',
        DebugLogType.error,
      );
      throw StateError(
        response.message ??
            'GetBarcodeFormat failed (message_code=${response.messageCode})',
      );
    }

    final now = DateTime.now();
    final valid = <BarcodeFormatConfig>[];

    for (final item in response.toConfigs(fetchedAt: now)) {
      final validation = BarcodeConfigValidator.validate(item);
      if (!validation.isValid) {
        printDebug(
          'BarcodeFormat skip invalid item ${item.tagFunction}: '
          '${validation.errorCode}',
          DebugLogType.error,
        );
        continue;
      }
      valid.add(item);
    }

    if (valid.isEmpty) {
      throw StateError('GetBarcodeFormat returned no valid formats');
    }

    return valid;
  }
}
