import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bs_mobile/src/shared/ui/notification/custom_show_alert.dart';

import 'package:bs_mobile/src/shared/ui/widgets/custom_button.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_card.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_gradient_app_bar.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_loading.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_text_field.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfigUrlPage extends StatefulWidget {
  const ConfigUrlPage({super.key});

  @override
  State<ConfigUrlPage> createState() => _ConfigUrlPageState();
}

class _ConfigUrlPageState extends State<ConfigUrlPage> {
  final TextEditingController urlKeyController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  final FocusNode urlKeyFocusNode = FocusNode();
  final FocusNode licenseFocusNode = FocusNode();

  @override
  void initState() {
    urlKeyFocusNode.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    urlKeyController.dispose();
    licenseController.dispose();
    urlKeyFocusNode.dispose();
    licenseFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<ConfigUrlBloc, ConfigUrlState>(
      listener: (context, state) {
        if (state is ConfigUrlLoading) {
          CustomLoading.show(text: 'Connecting...');
        }
        if (state is ConfigUrlSuccess) {
          CustomLoading.dismiss(
            messageText: state.message,
            alertType: CustomAlertType.success,
          );
          setState(() {});
        } else if (state is ConfigUrlFailure) {
          CustomLoading.dismiss(
            messageText: state.message,
            alertType: CustomAlertType.error,
          );
        }
      },
      child: Scaffold(
        appBar: CustomGradientAppBar(title: 'Settings'),
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
                                    cs.primary.withOpacity(0.2),
                                    cs.primaryContainer.withOpacity(0.1),
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
                      'Server Configuration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    AppText(
                      'Configure your server connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomCard(
                      title: 'Server URL',
                      subtitle: 'Enter your server URL key',
                      icon: Icons.dns_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            focusNode: urlKeyFocusNode,
                            controller: urlKeyController,
                            labelText: 'URL Key',
                            hintText: 'Enter server URL key',
                            prefixIcon: Icon(Icons.link_rounded),
                            minLines: 1,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder(
                            future: AppStorage.getApi(),
                            builder: (context, data) {
                              final urlValue =
                                  data.data?.toString() ?? 'No URL configured';
                              return CustomInfoBox(
                                label: 'Current URL',
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
                            text: 'Connect Server',
                            icon: Icons.cloud_upload_rounded,
                            onPressed: () {
                              if (urlKeyController.text.isEmpty) {
                                CustomShowAlert.showError(
                                  'Please enter a URL key',
                                );
                                return;
                              }
                              final url = urlKeyController.text.endsWith('/')
                                  ? urlKeyController.text
                                  : '${urlKeyController.text}/';
                              BlocProvider.of<ConfigUrlBloc>(
                                context,
                              ).add(ConnectionTestRequested(url));
                            },
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
