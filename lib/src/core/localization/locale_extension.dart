import 'package:bs_mobile/src/core/localization/locale_service.dart';
import 'package:flutter/widgets.dart';

extension LocaleExtension on BuildContext {
  String tr(String key, {String? fallback, Map<String, String>? params}) {
    return LocaleServiceScope.of(
      this,
    ).tr(key, fallback: fallback, params: params);
  }
}
