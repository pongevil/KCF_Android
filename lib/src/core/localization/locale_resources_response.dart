import 'package:bs_mobile/src/core/localization/locale_mapper.dart';
import 'package:bs_mobile/src/core/localization/locale_resource.dart';
import 'package:bs_mobile/src/core/localization/locale_strings_response.dart';

class LocaleResourcesResponse {
  final String? messageCode;
  final String? messageText;
  final List<LocaleResource> data;

  const LocaleResourcesResponse({
    this.messageCode,
    this.messageText,
    required this.data,
  });

  factory LocaleResourcesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final resources = <LocaleResource>[];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          resources.add(
            LocaleResource.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return LocaleResourcesResponse(
      messageCode: json['message_code']?.toString(),
      messageText: json['message_text']?.toString(),
      data: resources,
    );
  }

  LocaleStringsResponse toLocaleStrings(String localeId) {
    return LocaleStringsResponse(
      localeId: localeId,
      messages: LocaleMapper.toMessages(data, localeId),
    );
  }
}
