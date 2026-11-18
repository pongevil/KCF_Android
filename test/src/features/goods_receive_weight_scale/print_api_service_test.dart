import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/service/print_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final label = GoodsReceiveLabel(
    id: 'label-1',
    labelNumber: 'LBL-001',
    bagNumber: 'BAG-001',
    skuCode: '0001122323',
    skuName: 'Test item',
    packagingName: 'Bag',
    cartId: 'CART-001',
    lineId: 'L01',
    lineName: 'Line 1',
    weightKg: 12.5,
    printWeightKg: 10,
    receiveDate: DateTime(2026, 10, 21),
    printedAt: DateTime(2026, 10, 21),
    status: 'printed',
    batchNo: '456 223 192 01',
    qrCode: 'LP2610210001',
  );

  setUp(
    () => SharedPreferences.setMockInitialValues({
      'url': 'http://172.16.250.102:98/',
    }),
  );

  test('builds the WeightSlip payload required by Print API', () {
    final payload = PrintApiService.buildPayload(
      labels: [label],
      printerIp: '10.60.10.135',
    );

    expect(payload['client'], {'id': 'android-07'});
    expect(payload['printer'], {
      'name': 'ZDesigner ZD621R-203dpi ZPL',
      'ip': '10.60.10.135',
    });
    expect(payload['template'], 'WeightSlip');
    expect(payload['copies'], 1);
    expect(payload['data'], [
      {
        'weight': '10 KG.',
        'item_code': '0001122323',
        'item_name': 'Test item',
        'batch_no': '456 223 192 01',
        'receive_date': '21/10/2026',
        'line_no': 'L01',
        'qr_code': 'LP2610210001',
      },
    ]);
  });

  test('posts with authorization, waitSeconds and idempotency key', () async {
    Uri? capturedUri;
    Map<String, String>? capturedHeaders;
    String? capturedBody;
    final traces = <String, Map<String, dynamic>>{};
    final service = PrintApiService(
      transport: (uri, headers, body, timeout) async {
        capturedUri = uri;
        capturedHeaders = headers;
        capturedBody = body;
        return const PrintApiTransportResponse(
          statusCode: 200,
          body: '{"status":"printed"}',
        );
      },
    );

    final message = await service.printLabels(
      [label],
      printerIp: '10.60.10.135',
      printerToken: 'mapping-token',
      traceWriter: (stage, payload) async => traces[stage] = payload,
    );

    expect(capturedUri?.host, '172.16.250.102');
    expect(capturedUri?.port, 48766);
    expect(capturedUri?.path, '/api/v1/print');
    expect(capturedUri?.queryParameters['waitSeconds'], '10');
    expect(capturedHeaders?['authorization'], 'Bearer mapping-token');
    expect(
      capturedHeaders?['Idempotency-Key'],
      startsWith('android-07-print-'),
    );
    expect(jsonDecode(capturedBody!)['data'], [
      {
        'weight': '10 KG.',
        'item_code': '0001122323',
        'item_name': 'Test item',
        'batch_no': '456 223 192 01',
        'receive_date': '21/10/2026',
        'line_no': 'L01',
        'qr_code': 'LP2610210001',
      },
    ]);
    expect(message, 'printed');
    expect(traces.keys, containsAll(['PRINT_API_INPUT', 'PRINT_API_OUTPUT']));
    expect(traces['PRINT_API_INPUT']?['payload'], jsonDecode(capturedBody!));
    expect(
      traces['PRINT_API_INPUT'].toString(),
      isNot(contains('mapping-token')),
    );
    expect(traces['PRINT_API_OUTPUT']?['status_code'], 200);
    expect(
      traces['PRINT_API_OUTPUT']?['response_body'],
      '{"status":"printed"}',
    );
  });

  test('uses the latest server host saved in configuration', () async {
    final capturedUris = <Uri>[];
    final service = PrintApiService(
      transport: (uri, headers, body, timeout) async {
        capturedUris.add(uri);
        return const PrintApiTransportResponse(
          statusCode: 200,
          body: '{"status":"printed"}',
        );
      },
    );

    await service.printLabels(
      [label],
      printerIp: '172.16.250.100',
      printerToken: 'mapping-token',
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('url', 'http://192.168.1.20:98/');
    await service.printLabels(
      [label],
      printerIp: '172.16.250.100',
      printerToken: 'mapping-token',
    );

    expect(capturedUris.map((uri) => uri.host), [
      '172.16.250.102',
      '192.168.1.20',
    ]);
    expect(capturedUris.map((uri) => uri.port), everyElement(48766));
  });

  test('creates a different idempotency key for every print request', () async {
    final capturedKeys = <String>[];
    final service = PrintApiService(
      transport: (uri, headers, body, timeout) async {
        capturedKeys.add(headers['Idempotency-Key']!);
        return const PrintApiTransportResponse(
          statusCode: 200,
          body: '{"status":"printed"}',
        );
      },
    );

    await service.printLabels(
      [label],
      printerIp: '10.60.10.135',
      printerToken: 'mapping-token',
    );
    await service.printLabels(
      [label],
      printerIp: '10.60.10.135',
      printerToken: 'mapping-token',
    );

    expect(capturedKeys, hasLength(2));
    expect(capturedKeys[0], isNot(capturedKeys[1]));
    expect(capturedKeys[0], matches(r'^android-07-print-\d{8}-\d+$'));
  });

  test('sends Thai item names as UTF-8 JSON', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final receivedBody = Completer<String>();
    final subscription = server.listen((request) async {
      expect(request.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(request.headers.contentType?.charset, 'utf-8');
      receivedBody.complete(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = HttpStatus.ok
        ..write('{"status":"printed"}');
      await request.response.close();
    });
    addTearDown(subscription.cancel);
    final thaiLabel = GoodsReceiveLabel(
      id: label.id,
      labelNumber: label.labelNumber,
      bagNumber: label.bagNumber,
      skuCode: '101010001',
      skuName: 'หัวไก่เนื้อ',
      packagingName: label.packagingName,
      cartId: label.cartId,
      lineId: label.lineId,
      lineName: label.lineName,
      weightKg: 0.89,
      printWeightKg: 10,
      receiveDate: label.receiveDate,
      printedAt: label.printedAt,
      status: label.status,
      batchNo: label.batchNo,
      qrCode: label.qrCode,
    );
    final service = PrintApiService(
      baseUrl: 'http://${server.address.address}:${server.port}',
    );

    await service.printLabels(
      [thaiLabel],
      printerIp: '10.60.10.135',
      printerToken: 'mapping-token',
    );

    final decoded =
        jsonDecode(await receivedBody.future) as Map<String, dynamic>;
    expect((decoded['data'] as List).single['item_name'], 'หัวไก่เนื้อ');
  });
}
