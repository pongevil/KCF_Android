import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bs_mobile/src/features/config_url/presentation/pages/config_url_page.dart';
import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:bs_mobile/src/features/device_settings/models/device_connection_settings.dart';
import 'package:bs_mobile/src/features/device_settings/repository/device_settings_repository.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({
    super.key,
    required this.repository,
    GoodsReceiveRepository? goodsReceiveRepository,
  }) : _goodsReceiveRepository = goodsReceiveRepository;

  final DeviceSettingsRepository repository;
  final GoodsReceiveRepository? _goodsReceiveRepository;

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  final _packingLineFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;
  List<WeightScaleMapping> _scaleMappings = [];
  String? _selectedPackingLine;
  WeightScaleMapping? _selectedMapping;
  String? _currentApiUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final settings = await widget.repository.load();
    final currentApiUrl = await AppStorage.getApi();
    if (!mounted) return;

    List<WeightScaleMapping> mappings = [];
    try {
      if (widget._goodsReceiveRepository != null) {
        mappings = await widget._goodsReceiveRepository!.fetchScaleMappings();
      }
    } catch (e) {
      if (mounted) {
        CustomShowAlert.showWarning(
          context.tr(
            'device_settings.load_packing_lines_failed',
            fallback: 'Failed to load packing lines: {error}',
            params: {'error': e.toString()},
          ),
        );
      }
    }

    if (!mounted) return;

    WeightScaleMapping? selectedMapping;
    if (settings.packingLine.isNotEmpty) {
      try {
        selectedMapping = mappings.firstWhere(
          (m) => m.packingLine == settings.packingLine,
        );
      } catch (e) {
        // Not found
      }
    }

    setState(() {
      _scaleMappings = mappings;
      _selectedPackingLine = settings.packingLine.isNotEmpty
          ? settings.packingLine
          : null;
      _selectedMapping = selectedMapping;
      _currentApiUrl = currentApiUrl;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _packingLineFocus.dispose();
    super.dispose();
  }

  DeviceConnectionSettings _settingsFromForm() =>
      DeviceConnectionSettings(packingLine: _selectedPackingLine ?? '');

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.repository.save(_settingsFromForm());
    if (!mounted) return;
    setState(() => _saving = false);
    CustomShowAlert.showSuccess(
      context.tr(
        'device_settings.saved',
        fallback: 'บันทึกการตั้งค่าอุปกรณ์แล้ว',
      ),
    );
  }

  Future<void> _openServerConfiguration() async {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      await context.push('/configurl');
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider(
            create: (_) =>
                ConfigUrlBloc(ConfigUrlRepository(getIt<ApiClient>())),
            child: const ConfigUrlPage(),
          ),
        ),
      );
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CustomGradientAppBar(
      title: context.tr('device_settings.title', fallback: 'Device Settings'),
      subtitle: context.tr(
        'device_settings.subtitle',
        fallback: 'ตั้งค่า Line ผลิต',
      ),
      variant: CustomGradientAppBarVariant.green,
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CustomCard(
                title: context.tr(
                  'device_settings.packing_line',
                  fallback: 'Config Line ผลิต',
                ),
                subtitle: context.tr(
                  'device_settings.packing_line_desc',
                  fallback: 'เลือก Line ผลิต',
                ),
                icon: Icons.production_quantity_limits_rounded,
                child: _scaleMappings.isEmpty
                    ? AppText(
                        context.tr(
                          'device_settings.no_packing_lines',
                          fallback: 'ไม่มี Packing Line ที่พร้อมใช้งาน',
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Customdropdown<WeightScaleMapping>(
                            label: context.tr(
                              'device_settings.packing_line',
                              fallback: 'Config Line ผลิต',
                            ),
                            hint: context.tr(
                              'device_settings.select_packing_line',
                              fallback: 'เลือก Packing Line',
                            ),
                            focusNode: _packingLineFocus,
                            value: _selectedMapping,
                            items: _scaleMappings,
                            itemToString: (mapping) => mapping.packingLine,
                            onChanged: (mapping) {
                              setState(() {
                                _selectedMapping = mapping;
                                _selectedPackingLine = mapping?.packingLine;
                              });
                            },
                          ),
                          if (_selectedMapping != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context.tr(
                                'device_settings.scale',
                                fallback: 'Scale',
                              ),
                              '${_selectedMapping!.scaleName} (${_selectedMapping!.scaleIp}:${_selectedMapping!.scalePort})',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context.tr(
                                'device_settings.printer',
                                fallback: 'Printer',
                              ),
                              '${_selectedMapping!.printerName} (${_selectedMapping!.printerIp})',
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              CustomCard(
                title: context.tr(
                  'server_config.title',
                  fallback: 'Server Configuration',
                ),
                subtitle:
                    _currentApiUrl ??
                    context.tr(
                      'server_config.not_configured',
                      fallback: 'Not configured',
                    ),
                icon: Icons.cloud_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      context.tr(
                        'device_settings.server_config_desc',
                        fallback:
                            'ตั้งค่า Gateway URL และ Endpoint สำหรับการเชื่อมต่อเซิร์ฟเวอร์',
                      ),
                      fontSize: 13,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: context.tr(
                        'device_settings.configure_server',
                        fallback: 'ตั้งค่าเซิร์ฟเวอร์',
                      ),
                      icon: Icons.settings_rounded,
                      onPressed: _openServerConfiguration,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  text: _saving
                      ? context.tr('common.saving', fallback: 'กำลังบันทึก...')
                      : context.tr('common.save', fallback: 'บันทึก'),
                  icon: Icons.save_rounded,
                  variant: _saving
                      ? CustomButtonVariant.disabled
                      : CustomButtonVariant.success,
                  onPressed: _saving ? null : _save,
                  width: 220,
                ),
              ),
            ],
          ),
  );

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        AppText('$label: ', fontSize: 13, fontWeight: FontWeight.w600),
        Expanded(
          child: AppText(value, fontSize: 13, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
