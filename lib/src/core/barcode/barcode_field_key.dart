/// Exact BE `tag_name` / `tag_function` constants — not an alias layer.
///
/// If BE renames a field, update the constant and call sites.
/// Do not add synonym maps or normalize/rewrite helpers.
abstract final class BarcodeFieldKey {
  static const itemNumber = 'item_number';
  static const batchNumber = 'batch_number';
  static const lot = 'lot';
  static const expiryDate = 'expiry_date';

  static const expirydate = 'expirydate';
  static const warehouseCode = 'warehouse_code';
  static const binLocation = 'bin_location';
}

/// Layout keys used when calling [BarcodeScanHelper] (`scanAndApply` / `applyRaw`).
///
/// Config is loaded via GetBarcodeFormat once; each screen picks the matching
/// [tag_function] so parse uses the correct fields (shared root separator).
abstract final class BarcodeTagFunction {
  /// Sample from real API payload.
  static const allFunction = 'allfunction';

  /// Placeholder until BE confirms every menu value.
  static const deliveryOrder = 'delivery_order';
}
