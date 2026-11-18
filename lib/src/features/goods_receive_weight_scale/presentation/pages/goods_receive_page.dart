import 'dart:async';

import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/core/helpers/quantity_formatter.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/features/device_settings/models/device_connection_settings.dart';
import 'package:bs_mobile/src/features/device_settings/repository/device_settings_repository.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/presentation/bloc/goods_receive_bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsReceivePage extends StatefulWidget {
  const GoodsReceivePage({super.key});

  @override
  State<GoodsReceivePage> createState() => _GoodsReceivePageState();
}

class _GoodsReceivePageState extends State<GoodsReceivePage> {
  final _cartController = TextEditingController();
  final _cartFocus = FocusNode();
  ReceiveSku? _sku;
  PackagingOption? _packaging;
  DeviceConnectionSettings? _deviceSettings;
  WeightScaleMapping? _selectedMapping;
  WeightReading? _latestReading;
  String _lastSubmittedCartId = '';
  Timer? _weightPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadDeviceSettings();
  }

  Future<void> _loadDeviceSettings() async {
    final deviceRepo = getIt<DeviceSettingsRepository>();
    final goodsRepo = getIt<GoodsReceiveRepository>();
    try {
      final settings = await deviceRepo.load();
      setState(() {
        _deviceSettings = settings;
      });

      if (settings.packingLine.isNotEmpty) {
        try {
          final mappings = await goodsRepo.fetchScaleMappings();
          WeightScaleMapping? mapping;
          for (final candidate in mappings) {
            if (candidate.packingLine == settings.packingLine) {
              mapping = candidate;
              break;
            }
          }
          if (mapping != null) {
            setState(() {
              _selectedMapping = mapping;
            });
          }
        } catch (e) {
          // Continue without mapping
        }
      }

      if (mounted) {
        context.read<GoodsReceiveBloc>().add(
          GoodsReceiveLoadRequested(settings.packingLine),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomShowAlert.showWarning('Failed to load device settings');
        context.read<GoodsReceiveBloc>().add(
          const GoodsReceiveLoadRequested(''),
        );
      }
    }
  }

  @override
  void dispose() {
    _weightPollingTimer?.cancel();
    _cartController.dispose();
    _cartFocus.dispose();
    super.dispose();
  }

  void _requestWeight(GoodsReceiveSetup setup, {bool silent = false}) {
    _weightPollingTimer?.cancel();
    if (!mounted) return;
    final bloc = context.read<GoodsReceiveBloc>();
    if (bloc.state is GoodsReceiveSubmitting ||
        bloc.state is GoodsReceiveClosing) {
      return;
    }
    bloc.add(
      GoodsReceiveWeightRequested(
        setup,
        scaleIp: _selectedMapping?.scaleIp ?? setup.station.scaleIp ?? '',
        scalePort: _selectedMapping?.scalePort ?? 4660,
        silent: silent,
      ),
    );
  }

  void _scheduleWeightRead(
    GoodsReceiveSetup setup, {
    Duration delay = const Duration(seconds: 1),
  }) {
    _weightPollingTimer?.cancel();
    _weightPollingTimer = Timer(delay, () {
      if (mounted) _requestWeight(setup, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoodsReceiveBloc, GoodsReceiveState>(
      listener: (context, state) {
        if (state is GoodsReceiveReady) {
          _cartFocus.requestFocus();
          _requestWeight(state.setup, silent: _latestReading != null);
        } else if (state is GoodsReceiveWeightReady) {
          _latestReading = state.reading;
          _scheduleWeightRead(state.setup);
        } else if (state is GoodsReceiveWeightFailure) {
          _scheduleWeightRead(state.setup, delay: const Duration(seconds: 2));
        } else if (state is GoodsReceiveSubmitting ||
            state is GoodsReceiveClosing) {
          _weightPollingTimer?.cancel();
        } else if (state is GoodsReceiveFailure) {
          CustomShowAlert.showWarning(state.message);
          if (state.setup != null) _scheduleWeightRead(state.setup!);
        } else if (state is GoodsReceiveSuccess) {
          CustomShowAlert.showSuccess(
            context.tr(
              'goods_receive.print_success',
              fallback: 'บันทึกและพิมพ์ Label สำเร็จ',
            ),
          );
          if (_lastSubmittedCartId.isNotEmpty &&
              _cartController.text.trim().isEmpty) {
            _cartController.value = TextEditingValue(
              text: _lastSubmittedCartId,
              selection: TextSelection.collapsed(
                offset: _lastSubmittedCartId.length,
              ),
            );
          }
          setState(() {
            _sku = null;
            _packaging = null;
          });
          _cartFocus.requestFocus();
          _requestWeight(state.setup, silent: _latestReading != null);
        } else if (state is GoodsReceiveCloseSuccess) {
          CustomShowAlert.showSuccess(state.message);
          _cartController.clear();
          _lastSubmittedCartId = '';
          _requestWeight(state.setup, silent: _latestReading != null);
        }
      },
      builder: (context, state) {
        final setup = switch (state) {
          GoodsReceiveReady s => s.setup,
          GoodsReceiveWeightLoading s => s.setup,
          GoodsReceiveWeightReady s => s.setup,
          GoodsReceiveWeightFailure s => s.setup,
          GoodsReceiveSubmitting s => s.setup,
          GoodsReceiveSuccess s => s.setup,
          GoodsReceiveClosing s => s.setup,
          GoodsReceiveCloseSuccess s => s.setup,
          GoodsReceiveFailure s => s.setup,
          _ => null,
        };
        final reading =
            switch (state) {
              GoodsReceiveWeightReady s => s.reading,
              GoodsReceiveSubmitting s => s.reading,
              GoodsReceiveFailure s => s.reading,
              _ => null,
            } ??
            _latestReading;
        return Scaffold(
          appBar: CustomGradientAppBar(
            title: context.tr(
              'goods_receive.title',
              fallback: 'รับสินค้าจากเครื่องชั่ง',
            ),
            subtitle: context.tr(
              'goods_receive.code',
              fallback: 'D0004 Goods Receive Weight Scale',
            ),
            variant: CustomGradientAppBarVariant.green,
          ),
          body: setup == null
              ? Center(
                  child: state is GoodsReceiveFailure
                      ? CustomButton(
                          text: context.tr('common.retry', fallback: 'ลองใหม่'),
                          onPressed: () => context.read<GoodsReceiveBloc>().add(
                            const GoodsReceiveLoadRequested(''),
                          ),
                        )
                      : const CircularProgressIndicator(),
                )
              : _responsiveContent(context, setup, reading, state),
        );
      },
    );
  }

  Widget _responsiveContent(
    BuildContext context,
    GoodsReceiveSetup setup,
    WeightReading? reading,
    GoodsReceiveState state,
  ) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth >= constraints.maxHeight;
          final designSize = landscape
              ? const Size(1180, 620)
              : const Size(720, 980);
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox.fromSize(
                size: designSize,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: landscape
                      ? _landscapeLayout(context, setup, reading, state)
                      : _portraitLayout(context, setup, reading, state),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _landscapeLayout(
    BuildContext context,
    GoodsReceiveSetup setup,
    WeightReading? reading,
    GoodsReceiveState state,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _stationCard(context, setup),
              const SizedBox(height: 10),
              _cartField(context),
              const SizedBox(height: 10),
              Expanded(child: _skuSelector(context, setup, 2)),
              const SizedBox(height: 10),
              _packagingSelector(context, setup),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(child: _weightPanel(context, setup, reading, state)),
              const SizedBox(height: 14),
              _actionButtons(context, setup, reading, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _portraitLayout(
    BuildContext context,
    GoodsReceiveSetup setup,
    WeightReading? reading,
    GoodsReceiveState state,
  ) {
    return Column(
      children: [
        _stationCard(context, setup),
        const SizedBox(height: 12),
        _cartField(context),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(child: _skuSelector(context, setup, 2)),
                    const SizedBox(height: 10),
                    _packagingSelector(context, setup),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _weightPanel(context, setup, reading, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _actionButtons(context, setup, reading, state),
      ],
    );
  }

  Widget _stationCard(BuildContext context, GoodsReceiveSetup setup) {
    final cs = context.colorScheme;
    final hasDeviceSettings =
        _deviceSettings != null && _deviceSettings!.packingLine.isNotEmpty;

    return CustomCard(
      title: context.tr('goods_receive.station', fallback: 'ข้อมูลจุดชั่ง'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _info(
                  context.tr('goods_receive.line', fallback: 'Line'),
                  setup.station.lineName,
                ),
              ),
              Expanded(
                child: _info(
                  context.tr('goods_receive.scale', fallback: 'เครื่องชั่ง'),
                  setup.station.scaleName,
                ),
              ),
              Expanded(
                child: _info(
                  context.tr('goods_receive.printer', fallback: 'Printer'),
                  setup.station.printerName,
                ),
              ),
              Expanded(
                child: _info('Batch No.', setup.latestBatch?.batchNo ?? 'N/A'),
              ),
            ],
          ),
          if (hasDeviceSettings) ...[
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _info(
                    'Scale IP:Port',
                    _selectedMapping != null
                        ? '${_selectedMapping!.scaleIp}:${_selectedMapping!.scalePort}'
                        : 'N/A',
                  ),
                ),
                Expanded(
                  child: _info(
                    'Printer IP:Port',
                    _selectedMapping != null
                        ? _selectedMapping!.printerIp
                        : 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cartField(BuildContext context) {
    return CustomTextField(
      controller: _cartController,
      focusNode: _cartFocus,
      labelText: context.tr(
        'goods_receive.cart_id',
        fallback: '1. Scan / ระบุ Cart ID',
      ),
      hintText: context.tr(
        'goods_receive.cart_hint',
        fallback: 'สแกนหมายเลขรถเข็น',
      ),
      prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
      keyboardType: TextInputType.none,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }

  Widget _skuSelector(
    BuildContext context,
    GoodsReceiveSetup setup,
    int columns,
  ) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          context.tr(
            'goods_receive.select_sku',
            fallback: '2. เลือก SKU สินค้า',
          ),
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Scrollbar(
            child: GridView.builder(
              key: const Key('goods-receive-sku-grid'),
              primary: false,
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: setup.skus.length,
              itemBuilder: (_, index) {
                final sku = setup.skus[index];
                final selected = sku == _sku;
                return InkWell(
                  onTap: () => setState(() => _sku = sku),
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: selected ? cs.primaryContainer : cs.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SkuImage(sku: sku, selected: selected),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                sku.name,
                                fontWeight: FontWeight.w600,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                sku.code,
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _packagingSelector(BuildContext context, GoodsReceiveSetup setup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          context.tr(
            'goods_receive.select_packaging',
            fallback: '3. เลือก Packaging',
          ),
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: setup.packagings
              .map(
                (packaging) => ChoiceChip(
                  label: Text(
                    '${packaging.name} '
                    '(${packaging.capacityKg.toStringAsFixed(0)} kg)',
                  ),
                  selected: packaging == _packaging,
                  onSelected: (_) => setState(() => _packaging = packaging),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _weightPanel(
    BuildContext context,
    GoodsReceiveSetup setup,
    WeightReading? reading,
    GoodsReceiveState state,
  ) {
    final cs = context.colorScheme;
    final displayWeightKg = reading == null
        ? null
        : QuantityFormatter.roundHalfUp(reading.weightKg, decimalPlaces: 2);
    final loading = state is GoodsReceiveWeightLoading;
    final weightFailure = state is GoodsReceiveWeightFailure;
    final hasPrintableWeight =
        reading?.isStable == true && (reading?.weightKg ?? 0) > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.scale_rounded, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          AppText(
            context.tr(
              'goods_receive.weight',
              fallback: '4. น้ำหนักจากเครื่องชั่ง',
            ),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 12),
          AppText(
            '${displayWeightKg?.toStringAsFixed(2) ?? '--'} kg',
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: cs.primary,
          ),
          const SizedBox(height: 8),
          AppText(
            loading
                ? context.tr(
                    'goods_receive.waiting_stable',
                    fallback: 'กำลังรอค่าน้ำหนักนิ่งจากเครื่องชั่ง...',
                  )
                : hasPrintableWeight
                ? context.tr(
                    'goods_receive.stable',
                    fallback: 'น้ำหนักนิ่ง พร้อมยืนยัน',
                  )
                : weightFailure
                ? context.tr(
                    'goods_receive.reconnecting_scale',
                    fallback: 'ไม่สามารถอ่านน้ำหนัก กำลังเชื่อมต่อใหม่...',
                  )
                : context.tr(
                    'goods_receive.waiting_weight',
                    fallback: 'กำลังเชื่อมต่อเครื่องชั่ง...',
                  ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _confirmButton(
    BuildContext context,
    GoodsReceiveSetup setup,
    WeightReading? reading,
    GoodsReceiveState state,
  ) {
    final isEnabled =
        reading != null &&
        reading.weightKg > 0 &&
        _cartController.text.trim().isNotEmpty &&
        _sku != null &&
        _packaging != null &&
        state is! GoodsReceiveSubmitting &&
        state is! GoodsReceiveClosing;

    return CustomButton(
      text: context.tr(
        'goods_receive.confirm_print',
        fallback: '5. ยืนยันรับสินค้าและพิมพ์ Label',
      ),
      icon: Icons.print_rounded,
      variant: CustomButtonVariant.success,
      height: 58,
      width: double.infinity,
      onPressed: !isEnabled
          ? null
          : () {
              final roundedWeightKg = QuantityFormatter.roundHalfUp(
                reading.weightKg,
                decimalPlaces: 2,
              );
              _lastSubmittedCartId = _cartController.text.trim();
              context.read<GoodsReceiveBloc>().add(
                GoodsReceiveSubmitRequested(
                  setup: setup,
                  reading: reading,
                  request: GoodsReceiveRequest(
                    cartId: _lastSubmittedCartId,
                    skuId: _sku?.id ?? '',
                    packagingId: _packaging?.id ?? '',
                    weightKg: roundedWeightKg,
                    lineId: setup.station.lineId,
                    scaleId: setup.station.scaleId,
                    printerId: setup.station.printerId,
                    batchNo: setup.latestBatch?.batchNo ?? '',
                    printerIp:
                        _selectedMapping?.printerIp ??
                        setup.station.printerIp ??
                        '',
                    printerToken: _selectedMapping?.printerToken ?? '',
                    traceId:
                        'GR-${DateTime.now().toUtc().microsecondsSinceEpoch}',
                  ),
                ),
              );
            },
    );
  }

  Widget _actionButtons(
    BuildContext context,
    GoodsReceiveSetup setup,
    WeightReading? reading,
    GoodsReceiveState state,
  ) {
    final busy =
        state is GoodsReceiveSubmitting || state is GoodsReceiveClosing;
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: context.tr(
              'goods_receive.close_order',
              fallback: 'Close Order',
            ),
            icon: Icons.inventory_2_outlined,
            variant: busy
                ? CustomButtonVariant.disabled
                : CustomButtonVariant.danger,
            height: 58,
            width: double.infinity,
            onPressed: busy ? null : () => _confirmCloseOrder(context, setup),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _confirmButton(context, setup, reading, state),
        ),
      ],
    );
  }

  Future<void> _confirmCloseOrder(
    BuildContext context,
    GoodsReceiveSetup setup,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: AppText(
          context.tr(
            'goods_receive.close_order_title',
            fallback: 'ยืนยันปิด Order',
          ),
          fontWeight: FontWeight.w700,
        ),
        content: AppText(
          context.tr(
            'goods_receive.close_order_message',
            fallback:
                'ปิด Order ล่าสุดของ Line ${setup.station.lineName} หรือไม่?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppText(context.tr('common.cancel', fallback: 'ยกเลิก')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppText(context.tr('common.confirm', fallback: 'ยืนยัน')),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<GoodsReceiveBloc>().add(GoodsReceiveCloseRequested(setup));
  }

  Widget _info(String label, String value) => Row(
    children: [
      AppText('$label: ', fontSize: 13, fontWeight: FontWeight.w600),
      Expanded(
        child: AppText(value, fontSize: 13, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

class _SkuImage extends StatelessWidget {
  const _SkuImage({required this.sku, required this.selected});

  final ReceiveSku sku;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallback = Icon(
      Icons.inventory_2_rounded,
      size: 38,
      color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );
    final imageUrl = sku.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return fallback;

    return SizedBox(
      width: 56,
      height: 48,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
