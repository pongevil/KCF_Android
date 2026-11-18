import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';

typedef PrintApiTransport =
    Future<PrintApiTransportResponse> Function(
      Uri uri,
      Map<String, String> headers,
      String body,
      Duration timeout,
    );
typedef PrintTraceWriter =
    Future<void> Function(String stage, Map<String, dynamic> payload);

class PrintApiTransportResponse {
  const PrintApiTransportResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

class PrintApiService {
  PrintApiService({String? baseUrl, PrintApiTransport? transport})
    : _baseUrlOverride = baseUrl?.trim(),
      _transport = transport ?? _sendWithHttpClient;

  static const clientId = 'android-07';
  static const printerName = 'ZDesigner ZD621R-203dpi ZPL';
  static const templateName = 'WeightSlip';
  static const printApiPort = 48766;
  static int _lastIdempotencyTimestamp = 0;

  final String? _baseUrlOverride;
  final PrintApiTransport _transport;

  Future<String> printLabels(
    List<GoodsReceiveLabel> labels, {
    required String printerIp,
    required String printerToken,
    PrintTraceWriter? traceWriter,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (labels.isEmpty) throw ArgumentError('No labels selected for printing');
    final bearerToken = printerToken.trim();
    if (bearerToken.isEmpty) {
      throw StateError('token_printer is not configured for this packing line');
    }

    final uri = await _buildPrintUri();
    final payload = buildPayload(labels: labels, printerIp: printerIp);
    final body = jsonEncode(payload);
    await _writeTrace(traceWriter, 'PRINT_API_INPUT', {
      'url': uri.toString(),
      'payload': payload,
    });
    late final PrintApiTransportResponse response;
    try {
      response = await _transport(
        uri,
        {
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
          'Idempotency-Key': _idempotencyKey(),
          HttpHeaders.contentTypeHeader:
              '${ContentType.json.mimeType}; charset=utf-8',
        },
        body,
        timeout,
      );
    } catch (error) {
      await _writeTrace(traceWriter, 'PRINT_API_EXCEPTION', {
        'url': uri.toString(),
        'error': error.toString(),
      });
      rethrow;
    }
    await _writeTrace(traceWriter, 'PRINT_API_OUTPUT', {
      'url': uri.toString(),
      'status_code': response.statusCode,
      'response_body': response.body,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Print API ${response.statusCode}: ${response.body}',
        uri: uri,
      );
    }

    final decoded = response.body.trim().isEmpty
        ? null
        : jsonDecode(response.body);
    if (decoded is Map) {
      return decoded['message']?.toString() ??
          decoded['message_text']?.toString() ??
          decoded['status']?.toString() ??
          'Print submitted successfully';
    }
    return 'Print submitted successfully';
  }

  Future<Uri> _buildPrintUri() async {
    final override = _baseUrlOverride;
    final configuredUrl = override?.isNotEmpty == true
        ? override!
        : (await AppStorage.getApi())?.trim() ?? '';
    final configuredUri = Uri.tryParse(configuredUrl);
    if (configuredUri == null ||
        configuredUri.host.isEmpty ||
        (configuredUri.scheme != 'http' && configuredUri.scheme != 'https')) {
      throw StateError('Server URL is not configured');
    }

    return configuredUri.replace(
      port: override?.isNotEmpty == true ? configuredUri.port : printApiPort,
      path: '/api/v1/print',
      queryParameters: const {'waitSeconds': '10'},
    );
  }

  static Future<void> _writeTrace(
    PrintTraceWriter? writer,
    String stage,
    Map<String, dynamic> payload,
  ) async {
    if (writer == null) return;
    try {
      await writer(stage, payload);
    } catch (_) {
      // Test tracing must never interrupt receiving or printing.
    }
  }

  static Map<String, dynamic> buildPayload({
    required List<GoodsReceiveLabel> labels,
    required String printerIp,
  }) {
    if (labels.any((label) => label.printWeightKg <= 0)) {
      throw StateError('Packaging capacity is not configured for printing');
    }
    return {
      'client': {'id': clientId},
      'printer': {'name': printerName, 'ip': printerIp},
      'template': templateName,
      'copies': 1,
      'data': labels
          .map(
            (label) => {
              'weight': '${_formatWeight(label.printWeightKg)} KG.',
              'item_code': label.skuCode,
              'item_name': label.skuName,
              'batch_no': label.batchNo,
              'receive_date': _formatDate(label.receiveDate),
              'line_no': label.lineId,
              'qr_code': label.qrCode.isEmpty
                  ? label.labelNumber
                  : label.qrCode,
            },
          )
          .toList(growable: false),
    };
  }

  static String _formatWeight(double value) {
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _idempotencyKey() {
    final now = DateTime.now().toUtc();
    final timestamp = now.microsecondsSinceEpoch > _lastIdempotencyTimestamp
        ? now.microsecondsSinceEpoch
        : _lastIdempotencyTimestamp + 1;
    _lastIdempotencyTimestamp = timestamp;
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return '$clientId-print-$date-$timestamp';
  }

  static Future<PrintApiTransportResponse> _sendWithHttpClient(
    Uri uri,
    Map<String, String> headers,
    String body,
    Duration timeout,
  ) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      request.add(utf8.encode(body));
      final response = await request.close().timeout(timeout);
      return PrintApiTransportResponse(
        statusCode: response.statusCode,
        body: await utf8.decoder.bind(response).join().timeout(timeout),
      );
    } finally {
      client.close(force: true);
    }
  }
}
