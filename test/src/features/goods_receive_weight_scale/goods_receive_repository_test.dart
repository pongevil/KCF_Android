import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/service/print_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class RecordingPrintApiService extends PrintApiService {
  RecordingPrintApiService();

  List<GoodsReceiveLabel> printedLabels = const [];
  String printedAtIp = '';
  String printedWithToken = '';

  @override
  Future<String> printLabels(
    List<GoodsReceiveLabel> labels, {
    required String printerIp,
    required String printerToken,
    PrintTraceWriter? traceWriter,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    printedLabels = labels;
    printedAtIp = printerIp;
    printedWithToken = printerToken;
    return 'printed';
  }
}

void main() {
  test('loads active scale mappings from WM3_API_Mobile', () async {
    final client = MockApiClient();
    final repository = GoodsReceiveRepository(client);
    const path = 'WM3_API_Mobile/api/WeightScaleMapping/GetMappings';
    when(() => client.get(path)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'is_success': true,
          'data': [
            {
              'scale_mapping_id': '1',
              'packing_line': 'LINE-01',
              'scale_name': 'Scale 1',
              'scale_ip': '10.10.60.51',
              'scale_port': 4660,
              'printer_name': 'Printer 1',
              'printer_ip': '10.10.60.61',
              'token_printer': 'line-01-token',
              'is_active': true,
            },
            {
              'scale_mapping_id': '2',
              'packing_line': 'LINE-02',
              'scale_name': 'Scale 2',
              'scale_ip': '10.10.60.52',
              'scale_port': 4660,
              'printer_name': 'Printer 2',
              'printer_ip': '10.10.60.62',
              'token_printer': 'line-02-token',
              'is_active': false,
            },
          ],
        },
      ),
    );

    final mappings = await repository.fetchScaleMappings();

    expect(mappings, hasLength(1));
    expect(mappings.single.packingLine, 'LINE-01');
    expect(mappings.single.printerToken, 'line-01-token');
    verify(() => client.get(path)).called(1);
  });

  test('loads SKU, packaging, and latest batch from setup endpoint', () async {
    final client = MockApiClient();
    final repository = GoodsReceiveRepository(client);
    const path = 'WM3_API_Mobile/api/GoodsReceiveWeightScale/Setup';
    when(
      () => client.get(path, queryParameters: {'device_id': 'LINE-01'}),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'is_success': true,
          'data': {
            'station': {
              'line_id': '1',
              'line_name': 'LINE-01',
              'scale_id': '1',
              'scale_name': 'Scale 1',
              'printer_id': '1',
              'printer_name': 'Printer 1',
            },
            'skus': [
              {'sku_id': 'SKU-ID', 'sku_code': 'SKU-01', 'sku_name': 'Chicken'},
            ],
            'packagings': [
              {
                'packaging_id': 'PACK-ID',
                'packaging_name': 'Bag 10 kg',
                'capacity_kg': 10,
              },
            ],
            'latest_batch': {
              'batch_master_id': 'BATCH-ID',
              'batch_no': '46569302',
              'production_date': '2026-10-29T00:00:00',
            },
          },
        },
      ),
    );

    final setup = await repository.fetchSetup(deviceId: 'LINE-01');

    expect(setup.skus.single.code, 'SKU-01');
    expect(setup.packagings.single.name, 'Bag 10 kg');
    expect(setup.packagings.single.capacityKg, 10);
    expect(setup.latestBatch?.batchNo, '46569302');
  });

  test('loads receipt labels for reprint from WM3_API_Mobile', () async {
    final client = MockApiClient();
    final repository = GoodsReceiveRepository(client);
    const path = 'WM3_API_Mobile/api/GoodsReceiveWeightScale/Labels';
    when(
      () => client.get(
        path,
        queryParameters: {'line_id': null, 'search_text': null},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'is_success': true,
          'data': [
            {
              'label_id': 'RECEIPT-DETAIL-ID',
              'label_number': '26110200004',
              'bag_number': '26110200004',
              'sku_code': '101010001',
              'sku_name': 'หัวไก่เนื้อ',
              'packaging_name': '10 kg',
              'cart_id': 'CART-01',
              'line_id': 'TEST Packing Line 1',
              'line_name': 'TEST Packing Line 1',
              'weight_kg': 0.89,
              'print_weight_kg': 10,
              'receive_date': '2026-11-02T00:00:00',
              'printed_at': '2026-11-02T11:18:13',
              'status': 'received',
              'batch_no': '46669302A',
              'qr_code': '26110200004',
            },
          ],
        },
      ),
    );

    final labels = await repository.fetchLabels();

    expect(labels, hasLength(1));
    expect(labels.single.labelNumber, '26110200004');
    expect(labels.single.skuName, 'หัวไก่เนื้อ');
    expect(labels.single.batchNo, '46669302A');
    expect(labels.single.weightKg, 0.89);
    expect(labels.single.printWeightKg, 10);
    verify(
      () => client.get(
        path,
        queryParameters: {'line_id': null, 'search_text': null},
      ),
    ).called(1);
  });

  test('uses latest batch in the primary print payload', () async {
    final client = MockApiClient();
    final printer = RecordingPrintApiService();
    final repository = GoodsReceiveRepository(client, printApiService: printer);
    const path = 'WM3_API_Mobile/api/GoodsReceiveWeightScale/Receive';
    const request = GoodsReceiveRequest(
      cartId: 'CART-01',
      skuId: 'SKU-ID',
      packagingId: 'PACK-ID',
      weightKg: 9.89,
      lineId: 'LINE-01',
      scaleId: 'SCALE-ID',
      printerId: 'PRINTER-ID',
      batchNo: '46569302',
      printerIp: '10.10.60.61',
      printerToken: 'line-01-token',
    );
    when(() => client.post(path, data: request.toJson())).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'data': {
            'label_id': 'LABEL-ID',
            'label_number': 'LABEL-001',
            'sku_code': 'SKU-01',
            'sku_name': 'Chicken',
            'packaging_name': 'Bag 10 kg',
            'cart_id': 'CART-01',
            'line_id': 'LINE-01',
            'line_name': 'LINE-01',
            'weight_kg': 9.89,
            'print_weight_kg': 10,
            'receive_date': '2026-10-29T00:00:00',
            'printed_at': '2026-10-29T10:00:00',
            'status': 'received',
          },
        },
      ),
    );

    final label = await repository.receive(request);

    expect(label.batchNo, '46569302');
    expect(label.weightKg, 9.89);
    expect(label.printWeightKg, 10);
    expect(printer.printedLabels.single.batchNo, '46569302');
    expect(printer.printedLabels.single.printWeightKg, 10);
    expect(printer.printedAtIp, '10.10.60.61');
    expect(printer.printedWithToken, 'line-01-token');
  });

  test('closes latest order using the tablet scale mapping', () async {
    final client = MockApiClient();
    final repository = GoodsReceiveRepository(client);
    const path = 'WM3_API_Mobile/api/GoodsReceiveWeightScale/CloseLatestOrder';
    when(
      () => client.post(path, data: {'scale_mapping_id': 'SCALE-MAPPING-ID'}),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'is_success': true,
          'message_code': '0',
          'message': 'Order closed successfully',
          'data': {
            'scale_mapping_id': 'SCALE-MAPPING-ID',
            'packing_line': 'LINE-01',
            'closed': true,
          },
        },
      ),
    );

    final message = await repository.closeLatestOrder(
      scaleMappingId: 'SCALE-MAPPING-ID',
    );

    expect(message, 'Order closed successfully');
    verify(
      () => client.post(path, data: {'scale_mapping_id': 'SCALE-MAPPING-ID'}),
    ).called(1);
  });
}
