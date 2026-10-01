import 'package:bs_mobile/src/core/app_config/quantity_config.dart';

class AppConfigService {
  AppConfigService._();

  static final AppConfigService instance = AppConfigService._();

  QuantityConfig _quantity = QuantityConfig.defaults;

  QuantityConfig get quantity => _quantity;

  void applyQuantity(QuantityConfig quantity) {
    _quantity = quantity;
  }
}
