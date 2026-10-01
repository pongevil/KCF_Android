import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeFormatResponse', () {
    test('parses real API envelope and groups by field tag_function', () {
      final response = BarcodeFormatResponse.fromJson({
        'separator': '|',
        'fields': [
          {
            'tag_function': 'allfunction',
            'tag_name': 'item_number',
            'tag_sequence': 1,
            'required': 'YES',
            'data_type': 'string',
            'format': null,
          },
          {
            'tag_function': 'allfunction',
            'tag_name': 'expirydate',
            'tag_sequence': 2,
            'required': 'YES',
            'data_type': 'string',
            'format': null,
          },
          {
            'tag_function': 'delivery_order',
            'tag_name': 'batch_number',
            'tag_sequence': 1,
            'required': 'NO',
            'data_type': 'string',
            'format': null,
          },
        ],
        'message_code': '0',
        'is_success': true,
        'message': 'SUCCESS',
        'total_records': 0,
        'total_pages': 0,
      });

      expect(response.messageCode, '0');
      expect(response.isSuccess, isTrue);
      expect(response.message, 'SUCCESS');
      expect(response.separator, '|');
      expect(response.totalPages, 0);
      expect(response.totalRecords, 0);
      expect(response.fields, hasLength(3));
      expect(response.fields.first.required, isTrue);
      expect(response.fields.first.tagFunction, 'allfunction');
      expect(response.fields.last.required, isFalse);

      final configs = response.toConfigs(fetchedAt: DateTime(2026, 1, 1));
      expect(configs, hasLength(2));

      final allFn = configs.firstWhere((c) => c.tagFunction == 'allfunction');
      expect(allFn.separator, '|');
      expect(allFn.fields, hasLength(2));
      expect(allFn.fields.map((f) => f.tagName), ['item_number', 'expirydate']);

      final delivery = configs.firstWhere(
        (c) => c.tagFunction == 'delivery_order',
      );
      expect(delivery.fields.single.tagName, 'batch_number');
    });

    test('BarcodeFormatConfig.fromJson accepts grouped slim item', () {
      final config = BarcodeFormatConfig.fromJson({
        'message_code': '0',
        'is_success': true,
        'message': null,
        'separator': '|',
        'tag_function': 'delivery_order',
        'total_pages': 0,
        'total_records': 1,
        'fields': [
          {
            'tag_sequence': 1,
            'tag_name': 'batch_number',
            'data_type': 'string',
            'required': 'YES',
            'format': null,
          },
        ],
      });

      expect(config.tagFunction, 'delivery_order');
      expect(config.fields.single.required, isTrue);
    });

    test('BarcodeFormatListResponse parses disk items array', () {
      final list = BarcodeFormatListResponse.fromJson({
        'message_code': '0',
        'is_success': true,
        'message': 'Success',
        'total_pages': 1,
        'total_records': 2,
        'items': [
          {
            'separator': '|',
            'tag_function': 'delivery_order',
            'fields': [
              {
                'tag_sequence': 1,
                'tag_name': 'batch_number',
                'data_type': 'string',
                'required': true,
              },
            ],
          },
          {
            'separator': '|',
            'tag_function': 'putaway',
            'fields': [
              {
                'tag_sequence': 1,
                'tag_name': 'bin_location',
                'data_type': 'string',
                'required': true,
              },
            ],
          },
        ],
      });

      expect(list.isSuccess, isTrue);
      expect(list.items, hasLength(2));
      expect(list.items.first.tagFunction, 'delivery_order');
      expect(list.items.last.tagFunction, 'putaway');
    });

    test('BarcodeFormatListResponse groups real API shape without items', () {
      final list = BarcodeFormatListResponse.fromJson({
        'separator': '|',
        'fields': [
          {
            'tag_function': 'allfunction',
            'tag_name': 'item_number',
            'tag_sequence': 1,
            'required': 'YES',
            'data_type': 'string',
          },
        ],
        'message_code': '0',
        'is_success': true,
        'message': 'SUCCESS',
      });

      expect(list.items, hasLength(1));
      expect(list.items.single.tagFunction, 'allfunction');
      expect(list.items.single.fields.single.tagName, 'item_number');
    });
  });
}
