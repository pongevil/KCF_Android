import 'dart:async';

import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/core/app_identity.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:bs_mobile/src/core/localization/locale_extension.dart';
import 'package:bs_mobile/src/global/blocs/app_config/app_config_bloc.dart';
import 'package:bs_mobile/src/global/blocs/locale/locale_bloc.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/features/auth/models/auth_model.dart';
import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:bs_mobile/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../shared/ui/index.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _onEnter() async {
    // // _testProgress();
    // // Navigator.pushNamed(context, Routes.home);

    final apiUrl = await AppStorage.getApi();
    if (!mounted) return;

    if (apiUrl == null) {
      context.push(Routes.configurl);
      CustomShowAlert.showWarning('Please set the API URL first');
      return;
    }

    if (_formKey.currentState!.validate()) {
      BlocProvider.of<AuthBloc>(context).add(
        AuthLoginEvent(
          AuthLoginRequest(
            applicationLicense: AppIdentity.applicationLicense,
            username: _usernameController.text,
            password: _passwordController.text,
            platform: AppIdentity.platform,
          ),
        ),
      );
    } else {
      if (_usernameController.text.isEmpty) {
        _usernameFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthSuccess) {
            CustomShowAlert.showSuccess(
              state.authResponseModel?.messageText ?? 'Login success',
            );
            final localeBloc = context.read<LocaleBloc>();
            final appConfigBloc = context.read<AppConfigBloc>();

            final localeReady = localeBloc.stream.firstWhere(
              (localeState) =>
                  localeState is LocaleLoaded || localeState is LocaleFailure,
            );
            final appConfigReady = appConfigBloc.stream.firstWhere(
              (configState) =>
                  configState is AppConfigLoaded ||
                  configState is AppConfigFailure,
            );

            localeBloc.add(LoadLocaleEvent());
            appConfigBloc.add(LoadAppConfigEvent());

            await Future.wait([localeReady, appConfigReady]);
            // Prefetch all barcode formats (non-blocking for home navigate).
            unawaited(getIt<BarcodeFormatService>().prefetchAll());
            if (!context.mounted) return;
            context.go(Routes.home);
          } else if (state is AuthFailure) {
            CustomLoading.dismiss();
            CustomShowAlert.showWarning(state.message);
          }
        },
        child: Scaffold(
          body: CustomAnimatedBackground(
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 40.0,
                            ),
                            child: CustomLoginCard(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  //Logo
                                  SizedBox(
                                    height: 120,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cs.surface,
                                        border: Border.all(
                                          color: cs.outlineVariant,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(
                                              context,
                                            ).shadowColor.withOpacity(0.05),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.asset(
                                          'assets/oga.png',
                                          fit: BoxFit.contain,
                                          scale: 1,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    minLines: 1,
                                    maxLines: 1,
                                    controller: _usernameController,
                                    labelText: context.tr(
                                      'username',
                                      fallback: 'Username',
                                    ),
                                    hintText: context.tr(
                                      'enter_your_username',
                                      fallback: 'Enter your username',
                                    ),
                                    prefixIcon: Icon(Icons.person_outline),
                                    focusNode: _usernameFocus,
                                    onChanged: (p0) {
                                      _formKey.currentState?.validate();
                                    },
                                    onFieldSubmitted: (p0) =>
                                        _passwordFocus.requestFocus(),
                                    validator: (p0) {
                                      if (p0 == null || p0.isEmpty) {
                                        return 'Username is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icon(Icons.lock_outline),
                                    focusNode: _passwordFocus,
                                    minLines: 1,
                                    maxLines: 1,
                                    onChanged: (p0) {
                                      _formKey.currentState?.validate();
                                    },
                                    validator: (p0) {
                                      if (p0 == null || p0.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (p0) => _onEnter(),
                                  ),
                                  const SizedBox(height: 28),
                                  CustomButton(
                                    text: 'Login',
                                    icon: Icons.login_rounded,
                                    variant: CustomButtonVariant.primary,
                                    onPressed: _onEnter,
                                    height: 54,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    text: 'Settings',
                                    icon: Icons.settings_outlined,
                                    backgroundColor: cs
                                        .surfaceContainerHighest, // Gray/Mint for secondary action
                                    textColor: cs.onSurface,
                                    onPressed: () {
                                      context.push(Routes.configurl);
                                    },
                                    height: 54,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      AppText(
                                        context.tr(
                                          'mobile.version',
                                          fallback:
                                              'Version ${_packageInfo.version}',
                                        ),
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
