import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/features/device_settings/repository/device_settings_repository.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/presentation/bloc/reprint_label_bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ReprintLabelPage extends StatefulWidget {
  const ReprintLabelPage({super.key});
  @override
  State<ReprintLabelPage> createState() => _ReprintLabelPageState();
}

class _ReprintLabelPageState extends State<ReprintLabelPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final Set<String> _selected = {};
  String _packingLine = '';
  String _printerIp = '';
  String _printerToken = '';
  bool _deviceContextLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceContext();
  }

  Future<void> _loadDeviceContext() async {
    if (mounted) setState(() => _deviceContextLoading = true);
    try {
      final deviceRepo = getIt<DeviceSettingsRepository>();
      final goodsRepo = getIt<GoodsReceiveRepository>();
      final settings = await deviceRepo.load();
      final packingLine = settings.packingLine.trim();
      if (!mounted) return;
      if (packingLine.isEmpty) {
        setState(() {
          _packingLine = '';
          _printerIp = '';
          _printerToken = '';
          _deviceContextLoading = false;
        });
        CustomShowAlert.showWarning(
          context.tr(
            'reprint_label.device_line_required',
            fallback: 'กรุณาตั้งค่า Packing Line ใน Device Settings',
          ),
        );
        return;
      }

      final mappings = await goodsRepo.fetchScaleMappings();
      WeightScaleMapping? mapping;
      for (final candidate in mappings) {
        if (candidate.packingLine == packingLine) {
          mapping = candidate;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _packingLine = packingLine;
        _printerIp = mapping?.printerIp ?? '';
        _printerToken = mapping?.printerToken ?? '';
        _deviceContextLoading = false;
        _selected.clear();
      });
      _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deviceContextLoading = false);
      CustomShowAlert.showWarning(
        context.tr(
          'reprint_label.device_load_failed',
          fallback: 'ไม่สามารถโหลด Device Settings ได้',
        ),
      );
    }
  }

  void _load() {
    if (_packingLine.isEmpty) return;
    context.read<ReprintLabelBloc>().add(
      ReprintLabelsLoadRequested(
        lineId: _packingLine,
        searchText: _searchController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReprintLabelBloc, ReprintLabelState>(
      listener: (context, state) {
        if (state is ReprintLabelFailure) {
          CustomShowAlert.showWarning(state.message);
        } else if (state is ReprintLabelSuccess) {
          CustomShowAlert.showSuccess(state.message);
          setState(_selected.clear);
          _load();
        }
      },
      builder: (context, state) {
        final items = state is ReprintLabelLoaded
            ? state.items
            : const <GoodsReceiveLabel>[];
        return Scaffold(
          appBar: CustomGradientAppBar(
            title: context.tr('reprint_label.title', fallback: 'Reprint Label'),
            subtitle: context.tr(
              'reprint_label.subtitle',
              fallback: _packingLine.isEmpty
                  ? 'Goods Receiving'
                  : 'Goods Receiving • $_packingLine',
            ),
            variant: CustomGradientAppBarVariant.green,
            actionIcon: Icons.refresh_rounded,
            onActionPressed: _loadDeviceContext,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: CustomTextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  hintText: context.tr(
                    'reprint_label.search',
                    fallback: 'ค้นหา Label, SKU หรือ Cart ID',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _load(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Checkbox(
                      value:
                          items.isNotEmpty && _selected.length == items.length,
                      onChanged: (value) => setState(() {
                        _selected.clear();
                        if (value == true) {
                          _selected.addAll(items.map((e) => e.id));
                        }
                      }),
                    ),
                    AppText(
                      context.tr(
                        'reprint_label.select_all',
                        fallback: 'เลือกทั้งหมดที่แสดงอยู่',
                      ),
                    ),
                    const Spacer(),
                    AppText(
                      context.tr(
                        'reprint_label.count',
                        fallback: 'รายการ: {count}',
                        params: {'count': items.length.toString()},
                      ),
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _deviceContextLoading || state is ReprintLabelLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? Center(
                        child: AppText(
                          context.tr(
                            'reprint_label.empty',
                            fallback: 'ไม่พบรายการ Label',
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _labelCard(context, items[index]),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: CustomButton(
              text:
                  '${context.tr('reprint_label.print_selected', fallback: 'พิมพ์ Label ที่เลือก')} (${_selected.length})',
              icon: Icons.print_rounded,
              variant: CustomButtonVariant.success,
              onPressed: _selected.isEmpty
                  ? null
                  : () => context.read<ReprintLabelBloc>().add(
                      ReprintLabelsRequested(
                        items
                            .where((item) => _selected.contains(item.id))
                            .toList(growable: false),
                        printerIp: _printerIp,
                        printerToken: _printerToken,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _labelCard(BuildContext context, GoodsReceiveLabel item) {
    final cs = context.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _selected.contains(item.id),
              onChanged: (value) => setState(
                () => value == true
                    ? _selected.add(item.id)
                    : _selected.remove(item.id),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    item.bagNumber,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  AppText(
                    item.labelNumber,
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 24,
                    runSpacing: 6,
                    children: [
                      _field(
                        context.tr('reprint_label.sku', fallback: 'SKU'),
                        item.skuName,
                      ),
                      _field(
                        context.tr(
                          'reprint_label.packaging',
                          fallback: 'Packaging',
                        ),
                        item.packagingName,
                      ),
                      _field(
                        context.tr('reprint_label.weight', fallback: 'น้ำหนัก'),
                        '${item.weightKg.toStringAsFixed(2)} kg',
                      ),
                      _field(
                        context.tr('reprint_label.cart', fallback: 'รถเข็น'),
                        item.cartId,
                      ),
                      _field(
                        context.tr('reprint_label.line', fallback: 'Line'),
                        item.lineName,
                      ),
                      _field(
                        context.tr(
                          'reprint_label.printed_at',
                          fallback: 'พิมพ์ล่าสุด',
                        ),
                        DateFormat('dd/MM/yyyy HH:mm').format(item.printedAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('reprint_label.print', fallback: 'พิมพ์ซ้ำ'),
              icon: const Icon(Icons.print_rounded),
              color: cs.primary,
              onPressed: () => context.read<ReprintLabelBloc>().add(
                ReprintLabelsRequested(
                  [item],
                  printerIp: _printerIp,
                  printerToken: _printerToken,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontSize: 11,
          color: context.colorScheme.onSurfaceVariant,
        ),
        AppText(value, fontSize: 13, fontWeight: FontWeight.w600),
      ],
    ),
  );
}
