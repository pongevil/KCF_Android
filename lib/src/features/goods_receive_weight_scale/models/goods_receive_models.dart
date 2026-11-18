import 'package:equatable/equatable.dart';

class WeightScaleMapping extends Equatable {
  const WeightScaleMapping({
    required this.id,
    required this.packingLine,
    required this.scaleName,
    required this.scaleIp,
    required this.scalePort,
    required this.printerName,
    required this.printerIp,
    required this.printerToken,
    required this.isActive,
  });
  final String id,
      packingLine,
      scaleName,
      scaleIp,
      printerName,
      printerIp,
      printerToken;
  final int scalePort;
  final bool isActive;
  factory WeightScaleMapping.fromJson(Map<String, dynamic> j) =>
      WeightScaleMapping(
        id: j['scale_mapping_id']?.toString() ?? '',
        packingLine: j['packing_line']?.toString() ?? '',
        scaleName: j['scale_name']?.toString() ?? '',
        scaleIp: j['scale_ip']?.toString() ?? '',
        scalePort: int.tryParse(j['scale_port']?.toString() ?? '') ?? 4660,
        printerName: j['printer_name']?.toString() ?? '',
        printerIp: j['printer_ip']?.toString() ?? '',
        printerToken: j['token_printer']?.toString() ?? '',
        isActive: j['is_active'] == true || j['is_active'] == 'Y',
      );
  @override
  List<Object?> get props => [
    id,
    packingLine,
    scaleName,
    scaleIp,
    scalePort,
    printerName,
    printerIp,
    printerToken,
    isActive,
  ];
}

class WeightScaleStation extends Equatable {
  const WeightScaleStation({
    required this.lineId,
    required this.lineName,
    required this.scaleId,
    required this.scaleName,
    required this.printerId,
    required this.printerName,
    this.scaleIp,
    this.printerIp,
  });
  final String lineId, lineName, scaleId, scaleName, printerId, printerName;
  final String? scaleIp, printerIp;
  factory WeightScaleStation.fromJson(Map<String, dynamic> j) =>
      WeightScaleStation(
        lineId: j['line_id']?.toString() ?? '',
        lineName: j['line_name']?.toString() ?? '',
        scaleId: j['scale_id']?.toString() ?? '',
        scaleName: j['scale_name']?.toString() ?? '',
        printerId: j['printer_id']?.toString() ?? '',
        printerName: j['printer_name']?.toString() ?? '',
        scaleIp: j['scale_ip']?.toString(),
        printerIp: j['printer_ip']?.toString(),
      );
  @override
  List<Object?> get props => [
    lineId,
    lineName,
    scaleId,
    scaleName,
    printerId,
    printerName,
    scaleIp,
    printerIp,
  ];
}

class ReceiveSku extends Equatable {
  const ReceiveSku({
    required this.id,
    required this.code,
    required this.name,
    this.imageUrl,
  });
  final String id, code, name;
  final String? imageUrl;
  factory ReceiveSku.fromJson(Map<String, dynamic> j) => ReceiveSku(
    id: j['sku_id']?.toString() ?? '',
    code: j['sku_code']?.toString() ?? '',
    name: j['sku_name']?.toString() ?? '',
    imageUrl: j['image_url']?.toString(),
  );
  @override
  List<Object?> get props => [id, code, name, imageUrl];
}

class PackagingOption extends Equatable {
  const PackagingOption({
    required this.id,
    required this.name,
    required this.capacityKg,
  });
  final String id, name;
  final double capacityKg;
  factory PackagingOption.fromJson(Map<String, dynamic> j) => PackagingOption(
    id: j['packaging_id']?.toString() ?? '',
    name: j['packaging_name']?.toString() ?? '',
    capacityKg: double.tryParse(j['capacity_kg']?.toString() ?? '') ?? 0,
  );
  @override
  List<Object?> get props => [id, name, capacityKg];
}

class GoodsReceiveSetup extends Equatable {
  const GoodsReceiveSetup({
    required this.station,
    required this.skus,
    required this.packagings,
    this.latestBatch,
  });
  final WeightScaleStation station;
  final List<ReceiveSku> skus;
  final List<PackagingOption> packagings;
  final ReceiveBatch? latestBatch;
  factory GoodsReceiveSetup.fromJson(Map<String, dynamic> j) =>
      GoodsReceiveSetup(
        station: WeightScaleStation.fromJson(
          Map<String, dynamic>.from(j['station'] as Map? ?? const {}),
        ),
        skus: (j['skus'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ReceiveSku.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false),
        packagings: (j['packagings'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => PackagingOption.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false),
        latestBatch: j['latest_batch'] is Map
            ? ReceiveBatch.fromJson(
                Map<String, dynamic>.from(j['latest_batch'] as Map),
              )
            : null,
      );
  @override
  List<Object?> get props => [station, skus, packagings, latestBatch];
}

class ReceiveBatch extends Equatable {
  const ReceiveBatch({
    required this.id,
    required this.batchNo,
    required this.productionDate,
  });

  final String id;
  final String batchNo;
  final DateTime productionDate;

  factory ReceiveBatch.fromJson(Map<String, dynamic> j) => ReceiveBatch(
    id: j['batch_master_id']?.toString() ?? '',
    batchNo: j['batch_no']?.toString() ?? '',
    productionDate:
        DateTime.tryParse(j['production_date']?.toString() ?? '') ??
        DateTime.now(),
  );

  @override
  List<Object?> get props => [id, batchNo, productionDate];
}

class WeightReading extends Equatable {
  const WeightReading({
    required this.weightKg,
    required this.readAt,
    required this.isStable,
  });
  final double weightKg;
  final DateTime readAt;
  final bool isStable;
  factory WeightReading.fromJson(Map<String, dynamic> j) => WeightReading(
    weightKg: double.tryParse(j['weight_kg']?.toString() ?? '') ?? 0,
    readAt: DateTime.tryParse(j['read_at']?.toString() ?? '') ?? DateTime.now(),
    isStable: j['is_stable'] == true || j['is_stable'] == 'Y',
  );
  @override
  List<Object?> get props => [weightKg, readAt, isStable];
}

class GoodsReceiveRequest extends Equatable {
  const GoodsReceiveRequest({
    required this.cartId,
    required this.skuId,
    required this.packagingId,
    required this.weightKg,
    required this.lineId,
    required this.scaleId,
    required this.printerId,
    this.batchNo = '',
    this.printerIp = '',
    this.printerToken = '',
    this.traceId = '',
  });
  final String cartId, skuId, packagingId, lineId, scaleId, printerId;
  final String batchNo, printerIp, printerToken, traceId;
  final double weightKg;
  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    'sku_id': skuId,
    'packaging_id': packagingId,
    'weight_kg': weightKg,
    'line_id': lineId,
    'scale_id': scaleId,
    'printer_id': printerId,
    'batch_no': batchNo,
    'trace_id': traceId,
  };
  @override
  List<Object?> get props => [
    cartId,
    skuId,
    packagingId,
    weightKg,
    lineId,
    scaleId,
    printerId,
    batchNo,
    printerIp,
    printerToken,
    traceId,
  ];
}

class GoodsReceiveLabel extends Equatable {
  const GoodsReceiveLabel({
    required this.id,
    required this.labelNumber,
    required this.bagNumber,
    required this.skuCode,
    required this.skuName,
    required this.packagingName,
    required this.cartId,
    required this.lineId,
    required this.lineName,
    required this.weightKg,
    required this.printWeightKg,
    required this.receiveDate,
    required this.printedAt,
    required this.status,
    this.batchNo = '',
    this.qrCode = '',
  });
  final String id,
      labelNumber,
      bagNumber,
      skuCode,
      skuName,
      packagingName,
      cartId,
      lineId,
      lineName,
      status,
      batchNo,
      qrCode;
  final double weightKg, printWeightKg;
  final DateTime receiveDate, printedAt;
  factory GoodsReceiveLabel.fromJson(Map<String, dynamic> j) {
    final now = DateTime.now();
    return GoodsReceiveLabel(
      id: j['label_id']?.toString() ?? '',
      labelNumber: j['label_number']?.toString() ?? '',
      bagNumber: j['bag_number']?.toString() ?? '',
      skuCode: j['sku_code']?.toString() ?? '',
      skuName: j['sku_name']?.toString() ?? '',
      packagingName: j['packaging_name']?.toString() ?? '',
      cartId: j['cart_id']?.toString() ?? '',
      lineId: j['line_id']?.toString() ?? '',
      lineName: j['line_name']?.toString() ?? '',
      weightKg: double.tryParse(j['weight_kg']?.toString() ?? '') ?? 0,
      printWeightKg:
          double.tryParse(j['print_weight_kg']?.toString() ?? '') ?? 0,
      receiveDate:
          DateTime.tryParse(j['receive_date']?.toString() ?? '') ?? now,
      printedAt: DateTime.tryParse(j['printed_at']?.toString() ?? '') ?? now,
      status: j['status']?.toString() ?? '',
      batchNo: j['batch_no']?.toString() ?? '',
      qrCode: j['qr_code']?.toString() ?? j['label_number']?.toString() ?? '',
    );
  }

  GoodsReceiveLabel copyWith({String? batchNo, double? printWeightKg}) =>
      GoodsReceiveLabel(
        id: id,
        labelNumber: labelNumber,
        bagNumber: bagNumber,
        skuCode: skuCode,
        skuName: skuName,
        packagingName: packagingName,
        cartId: cartId,
        lineId: lineId,
        lineName: lineName,
        weightKg: weightKg,
        printWeightKg: printWeightKg ?? this.printWeightKg,
        receiveDate: receiveDate,
        printedAt: printedAt,
        status: status,
        batchNo: batchNo ?? this.batchNo,
        qrCode: qrCode,
      );
  @override
  List<Object?> get props => [
    id,
    labelNumber,
    bagNumber,
    skuCode,
    skuName,
    packagingName,
    cartId,
    lineId,
    lineName,
    weightKg,
    printWeightKg,
    receiveDate,
    printedAt,
    status,
    batchNo,
    qrCode,
  ];
}
