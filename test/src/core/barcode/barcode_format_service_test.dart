import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_repository.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements BarcodeFormatRepository {}

BarcodeFormatConfig _valid({
  String tagFunction = 'delivery_order',
  DateTime? fetchedAt,
}) {
  return BarcodeFormatConfig(
    separator: '|',
    tagFunction: tagFunction,
    fetchedAt: fetchedAt,
    fields: const [
      BarcodeFormatField(
        tagSequence: 1,
        tagName: 'batch_number',
        dataType: BarcodeDataType.string,
        required: true,
      ),
    ],
  );
}

void main() {
  late _MockRepo repo;
  late Directory tempDir;
  late BarcodeFormatService service;

  setUp(() async {
    repo = _MockRepo();
    tempDir = await Directory.systemTemp.createTemp('barcode_format_test_');
    service = BarcodeFormatService(repo, ttl: const Duration(hours: 12))
      ..debugCacheDirectory = tempDir;
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BarcodeFormatService get-all', () {
    test('fetchAll once then lookup by tag_function', () async {
      when(
        () => repo.fetchAll(),
      ).thenAnswer((_) async => [_valid(fetchedAt: DateTime.now())]);

      final first = await service.getFormat('delivery_order');
      final second = await service.getFormat('delivery_order');

      expect(first, isNotNull);
      expect(second?.tagFunction, 'delivery_order');
      verify(() => repo.fetchAll()).called(1);
    });

    test('uses disk LKG when get-all fails', () async {
      when(
        () => repo.fetchAll(),
      ).thenAnswer((_) async => [_valid(fetchedAt: DateTime.now())]);
      await service.getFormat('delivery_order');
      service.clearMemory();

      when(() => repo.fetchAll()).thenThrow(Exception('network'));

      final stale = await service.getFormat('delivery_order');
      expect(stale?.tagFunction, 'delivery_order');
      expect(stale?.fields.first.tagName, 'batch_number');
    });

    test('keeps LKG when remote returns only invalid items', () async {
      when(
        () => repo.fetchAll(),
      ).thenAnswer((_) async => [_valid(fetchedAt: DateTime.now())]);
      expect(await service.getFormat('delivery_order'), isNotNull);
      service.clearMemory();

      when(() => repo.fetchAll()).thenAnswer(
        (_) async => const [
          BarcodeFormatConfig(
            separator: '',
            tagFunction: 'delivery_order',
            fields: [],
          ),
        ],
      );

      // Repo would normally filter invalids; simulate empty list from repo.
      when(() => repo.fetchAll()).thenAnswer((_) async => []);

      final after = await service.getFormat('delivery_order');
      expect(after?.fields.first.tagName, 'batch_number');
    });

    test('dedupes concurrent get-all', () async {
      final completer = Completer<List<BarcodeFormatConfig>>();
      when(() => repo.fetchAll()).thenAnswer((_) => completer.future);

      final a = service.getFormat('delivery_order');
      final b = service.getFormat('delivery_order');
      completer.complete([_valid(fetchedAt: DateTime.now())]);

      final results = await Future.wait([a, b]);
      expect(results[0]?.tagFunction, 'delivery_order');
      expect(results[1]?.tagFunction, 'delivery_order');
      verify(() => repo.fetchAll()).called(1);
    });

    test('writes disk bundle file', () async {
      when(
        () => repo.fetchAll(),
      ).thenAnswer((_) async => [_valid(fetchedAt: DateTime.now())]);
      await service.prefetchAll();

      final file = File('${tempDir.path}/all.json');
      expect(await file.exists(), isTrue);
      final json = jsonDecode(await file.readAsString()) as Map;
      expect(json['items'], isA<List>());
      expect((json['items'] as List).first['tag_function'], 'delivery_order');
    });

    test('unknown tag_function returns null after load', () async {
      when(
        () => repo.fetchAll(),
      ).thenAnswer((_) async => [_valid(fetchedAt: DateTime.now())]);
      expect(await service.getFormat('unknown_menu'), isNull);
    });
  });
}
