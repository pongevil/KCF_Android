import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/core/localization/locale_extension.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:bs_mobile/src/shared/ui/notification/custom_show_alert.dart';

import 'package:bs_mobile/src/shared/ui/widgets/custom_button.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_card.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_gradient_app_bar.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_loading.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_text_field.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

class ConfigUrlPage extends StatefulWidget {
  const ConfigUrlPage({super.key});

  @override
  State<ConfigUrlPage> createState() => _ConfigUrlPageState();
}

class _ConfigUrlPageState extends State<ConfigUrlPage> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _hostFocusNode = FocusNode();
  final _portFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final repository = context.read<ConfigUrlBloc>().repository;
    final config = await repository.loadConfiguration();
    if (!mounted) return;
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hostFocusNode.requestFocus();
    });
  }

  void _submit() {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty) {
      CustomShowAlert.showError(
        context.tr(
          'server_config.host_required',
          fallback: 'Please enter a server IP or host',
        ),
      );
      _hostFocusNode.requestFocus();
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      CustomShowAlert.showError(
        context.tr(
          'server_config.port_invalid',
          fallback: 'Port must be between 1 and 65535',
        ),
      );
      _portFocusNode.requestFocus();
      return;
    }
    context.read<ConfigUrlBloc>().add(ConnectionTestRequested(host, port));
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _hostFocusNode.dispose();
    _portFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<ConfigUrlBloc, ConfigUrlState>(
      listener: (context, state) {
        if (state is ConfigUrlLoading) {
          CustomLoading.show(
            text: context.tr(
              'server_config.connecting',
              fallback: 'Connecting...',
            ),
          );
        }
        if (state is ConfigUrlSuccess) {
          CustomLoading.dismiss(
            messageText: context.tr(
              'server_config.connection_success',
              fallback: 'Connection server successful',
            ),
            alertType: CustomAlertType.success,
          );
          setState(() {});
        } else if (state is ConfigUrlFailure) {
          CustomLoading.dismiss(
            messageText: context.tr(
              'server_config.connection_failed',
              fallback: 'Failed to connect to server',
            ),
            alertType: CustomAlertType.error,
          );
        }
      },
      child: Scaffold(
        appBar: CustomGradientAppBar(
          title: context.tr('server_config.settings', fallback: 'Settings'),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [cs.surfaceContainerHighest, cs.surface, cs.surface],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primary.withValues(alpha: 0.2),
                                    cs.primaryContainer.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.settings_suggest_rounded,
                                size: 60,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      context.tr(
                        'server_config.title',
                        fallback: 'Server Configuration',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    AppText(
                      context.tr(
                        'server_config.subtitle',
                        fallback: 'Configure your server connection',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomCard(
                      title: context.tr(
                        'server_config.server',
                        fallback: 'Server',
                      ),
                      subtitle: context.tr(
                        'server_config.server_desc',
                        fallback: 'IP/host and port can be changed at any time',
                      ),
                      icon: Icons.dns_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            focusNode: _hostFocusNode,
                            controller: _hostController,
                            labelText: context.tr(
                              'server_config.ip_address',
                              fallback: 'IP Address / Host',
                            ),
                            hintText: ConfigUrlRepository.defaultHost,
                            prefixIcon: const Icon(Icons.dns_rounded),
                            minLines: 1,
                            maxLines: 1,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _portFocusNode.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            focusNode: _portFocusNode,
                            controller: _portController,
                            labelText: context.tr(
                              'server_config.port',
                              fallback: 'Port',
                            ),
                            hintText: ConfigUrlRepository.defaultPort
                                .toString(),
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            minLines: 1,
                            maxLines: 1,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder(
                            future: AppStorage.getApi(),
                            builder: (context, data) {
                              final urlValue =
                                  data.data?.toString() ??
                                  context.tr(
                                    'server_config.not_configured',
                                    fallback: 'No URL configured',
                                  );
                              return CustomInfoBox(
                                label: context.tr(
                                  'server_config.current_url',
                                  fallback: 'Current URL',
                                ),
                                value: urlValue,
                                icon: Icons.info_outline_rounded,
                                color: data.data != null
                                    ? context.appTheme.success
                                    : context.appTheme.warning,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: context.tr(
                              'server_config.connect',
                              fallback: 'Connect Server',
                            ),
                            icon: Icons.cloud_upload_rounded,
                            onPressed: _submit,
                            height: 54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
