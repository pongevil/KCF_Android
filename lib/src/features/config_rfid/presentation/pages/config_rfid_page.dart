import 'package:bs_mobile/index.dart';
import 'package:bs_mobile/src/features/config_rfid/presentation/bloc/config_rfid_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfigRfidPage extends StatelessWidget {
  const ConfigRfidPage({super.key});

  static const int _minPower = 1;
  static const int _maxPower = 33;

  void _showPowerPicker(BuildContext context, int? currentPower) {
    final cs = Theme.of(context).colorScheme;
    int selected = currentPower ?? _maxPower;

    showCustomModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Material(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: cs.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'เลือกระดับพลังงาน RFID',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        'ค่าที่เลือก: $selected',
                        style: TextStyle(
                          fontSize: 22,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Divider(color: cs.outlineVariant, height: 1),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _maxPower - _minPower + 1,
                        itemBuilder: (_, index) {
                          final power = _maxPower - index;
                          final isSelected = power == selected;
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$power',
                                  style: TextStyle(
                                    color: isSelected
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              'พลังงาน $power',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: cs.primary,
                                  )
                                : null,
                            onTap: () {
                              setModalState(() => selected = power);
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          label: const Text(
                            'บันทึก',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.read<ConfigRfidBloc>().add(
                              ConfigRfidPowerSetRequested(selected),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: const CustomGradientAppBar(title: 'Config RFID'),
      body: BlocBuilder<ConfigRfidBloc, ConfigRfidState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: app.neutralIconBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.wifi_tethering_rounded,
                              color: cs.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'พลังงาน RFID ปัจจุบัน',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.currentPower != null
                            ? '${state.currentPower}'
                            : '-',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ช่วงที่รองรับ: $_minPower – $_maxPower',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (state.statusMessage != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: state.statusIsError
                          ? cs.errorContainer
                          : cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.statusIsError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: state.statusIsError
                              ? cs.onErrorContainer
                              : cs.onPrimaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.statusMessage!,
                            style: TextStyle(
                              color: state.statusIsError
                                  ? cs.onErrorContainer
                                  : cs.onPrimaryContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 56,
                  child: state.isSetting
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text(
                            'ตั้งค่าพลังงาน',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () =>
                              _showPowerPicker(context, state.currentPower),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('รีเฟรชค่าปัจจุบัน'),
                  onPressed: () {
                    context.read<ConfigRfidBloc>().add(
                      const ConfigRfidPowerLoadRequested(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
