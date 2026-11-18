import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_endpoints.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/service/weight_scale_tcp_service.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/service/print_api_service.dart';

/// API boundary for D0004. The backend can bind each endpoint to its stored
/// procedure without changing the Flutter presentation or BLoC layers.
class GoodsReceiveRepository {
  GoodsReceiveRepository(
    this._client, {
    WeightScaleTcpService? scaleService,
    PrintApiService? printApiService,
  }) : _scaleService = scaleService,
       _printApiService = printApiService;
  final ApiClient _client;
  final WeightScaleTcpService? _scaleService;
  final PrintApiService? _printApiService;

  static const setupPath = ApiEndpoints.mobileGoodsReceiveSetup;
  static const weightPath = 'Mobile/GoodsReceiveWeightScale/Weight';
  static const receivePath = ApiEndpoints.mobileGoodsReceiveReceive;
  static const closePath = ApiEndpoints.mobileGoodsReceiveClose;
  static const testTracePath =
      'WM3_API_Mobile/api/GoodsReceiveWeightScale/TestTrace';
  static const labelsPath = ApiEndpoints.mobileGoodsReceiveLabels;
  static const reprintPath = 'Mobile/GoodsReceiveWeightScale/Reprint';
  static const scaleMappingsPath = ApiEndpoints.mobileWeightScaleMappings;

  Future<GoodsReceiveSetup> fetchSetup({required String deviceId}) async {
    final response = await _client.get(
      setupPath,
      queryParameters: {if (deviceId.isNotEmpty) 'device_id': deviceId},
    );
    return GoodsReceiveSetup.fromJson(_dataMap(response.data));
  }

  Future<WeightReading> readWeight({
    required String scaleId,
    required String scaleIp,
    required int scalePort,
  }) async {
    if (_scaleService != null) {
      return _scaleService.readStableWeight(
        scaleIp: scaleIp,
        scalePort: scalePort,
      );
    }
    final response = await _client.get(
      weightPath,
      queryParameters: {'scale_id': scaleId},
    );
    return WeightReading.fromJson(_dataMap(response.data));
  }

  Future<GoodsReceiveLabel> receive(GoodsReceiveRequest request) async {
    final response = await _client.post(receivePath, data: request.toJson());
    _throwWhenFailed(response.data, fallback: 'Unable to receive goods');
    final receivedLabel = GoodsReceiveLabel.fromJson(_dataMap(response.data));
    final label = receivedLabel.batchNo.isEmpty && request.batchNo.isNotEmpty
        ? receivedLabel.copyWith(batchNo: request.batchNo)
        : receivedLabel;
    if (_printApiService != null) {
      if (request.printerIp.trim().isEmpty) {
        throw StateError('Printer IP is not configured');
      }
      await _printApiService.printLabels(
        [label],
        printerIp: request.printerIp,
        printerToken: request.printerToken,
        traceWriter: (stage, payload) => _writeTestTrace(
          traceId: request.traceId,
          stage: stage,
          payload: payload,
        ),
      );
    }
    return label;
  }

  Future<void> _writeTestTrace({
    required String traceId,
    required String stage,
    required Map<String, dynamic> payload,
  }) async {
    if (traceId.trim().isEmpty) return;
    try {
      await _client.post(
        testTracePath,
        data: {'trace_id': traceId, 'stage': stage, 'payload': payload},
      );
    } catch (_) {
      // Temporary test tracing must not interrupt the production flow.
    }
  }

  Future<String> closeLatestOrder({required String scaleMappingId}) async {
    final response = await _client.post(
      closePath,
      data: {'scale_mapping_id': scaleMappingId},
    );
    _throwWhenFailed(response.data, fallback: 'Unable to close order');
    final body = response.data;
    return body is Map
        ? body['message']?.toString() ?? 'Order closed successfully'
        : 'Order closed successfully';
  }

  Future<List<GoodsReceiveLabel>> fetchLabels({
    String? lineId,
    String? searchText,
  }) async {
    final response = await _client.get(
      labelsPath,
      queryParameters: {'line_id': lineId, 'search_text': searchText},
    );
    final data = response.data is Map ? response.data['data'] : null;
    final list = data is List
        ? data
        : data is Map && data['items'] is List
        ? data['items'] as List
        : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => GoodsReceiveLabel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<String> reprintLabels(
    List<GoodsReceiveLabel> labels, {
    required String printerIp,
    required String printerToken,
  }) async {
    if (_printApiService != null) {
      return _printApiService.printLabels(
        labels,
        printerIp: printerIp,
        printerToken: printerToken,
      );
    }
    final response = await _client.post(
      reprintPath,
      data: {'label_ids': labels.map((label) => label.id).toList()},
    );
    final body = response.data;
    return body is Map
        ? body['message_text']?.toString() ?? 'Print command submitted'
        : 'Print command submitted';
  }

  Future<List<WeightScaleMapping>> fetchScaleMappings() async {
    final response = await _client.get(scaleMappingsPath);
    final body = response.data;
    if (body is Map && body['is_success'] == false) {
      throw AppException(
        body['message']?.toString() ?? 'Unable to load scale mappings',
      );
    }
    final data = body is Map ? body['data'] : null;
    final list = data is List
        ? data
        : data is Map && data['items'] is List
        ? data['items'] as List
        : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => WeightScaleMapping.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.isActive)
        .toList(growable: false);
  }

  Map<String, dynamic> _dataMap(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return Map<String, dynamic>.from(data is Map ? data : body as Map);
  }

  void _throwWhenFailed(dynamic body, {required String fallback}) {
    if (body is Map && body['is_success'] == false) {
      throw AppException(body['message']?.toString() ?? fallback);
    }
  }
}
