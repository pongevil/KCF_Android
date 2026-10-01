import 'package:bs_mobile/src/app/di/app_bloc_listeners.dart';
import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/global/blocs/app_config/app_config_bloc.dart';
import 'package:bs_mobile/src/global/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:bs_mobile/src/global/blocs/combobox/combobox_bloc.dart';
import 'package:bs_mobile/src/global/blocs/locale/locale_bloc.dart';
import 'package:bs_mobile/src/global/blocs/network/network_bloc.dart';
import 'package:bs_mobile/src/global/blocs/push_notification/push_notification_bloc.dart';
import 'package:bs_mobile/src/global/blocs/theme/theme_bloc.dart';
import 'package:bs_mobile/src/global/blocs/version/version_bloc.dart';
import 'package:bs_mobile/src/core/localization/locale_service.dart';
import 'package:bs_mobile/src/core/theme/theme_config.dart';
import 'package:bs_mobile/src/features/ai/presentation/bloc/ai_chat_bloc.dart';
import 'package:bs_mobile/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bs_mobile/src/features/home/presentation/bloc/menu_bloc.dart';
import 'package:bs_mobile/src/features/home/presentation/cubit/drawer_profile_cubit.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final bloc = getIt<NetworkBloc>();
            bloc.add(NetworkObserve(bloc));
            return bloc;
          },
        ),
        BlocProvider(
          create: (_) => getIt<LocaleBloc>()..add(LoadLocaleFromCacheEvent()),
        ),
        BlocProvider(create: (_) => getIt<AiChatBloc>()),
        BlocProvider(
          create: (_) =>
              getIt<AppConfigBloc>()..add(LoadAppConfigFromCacheEvent()),
        ),
        BlocProvider(
          create: (_) => getIt<BluetoothBloc>()..add(BluetoothObserve()),
        ),
        BlocProvider(create: (_) => getIt<ThemeBloc>()..add(ThemeLoaded())),
        BlocProvider(create: (_) => getIt<VersionBloc>()),
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<MenuBloc>()),
        BlocProvider(create: (_) => getIt<ConfigUrlBloc>()),
        BlocProvider(create: (_) => getIt<ComboboxBloc>()),
        BlocProvider(create: (_) => getIt<DrawerProfileCubit>()..load()),
        BlocProvider(
          create: (_) =>
              getIt<PushNotificationBloc>()..add(PushNotificationInit()),
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final botToast = BotToastInit();

  @override
  Widget build(BuildContext context) {
    final router = getIt<GoRouter>();

    return BlocListener<ThemeBloc, ThemeState>(
      listener: (context, themeState) {
        _setSystemUIOverlay(themeState.isDark);
      },
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setSystemUIOverlay(themeState.isDark);
          });
          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return LocaleServiceScope(
                notifier: LocaleService.instance,
                child: MaterialApp.router(
                  routerConfig: router,
                  debugShowCheckedModeBanner: false,
                  locale: _resolveLocale(localeState),
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en', 'GB'),
                    Locale('th', 'TH'),
                  ],
                  theme: ThemeConfig.theme(
                    palette: themeState.palette,
                    brightness: Brightness.light,
                  ),
                  darkTheme: ThemeConfig.theme(
                    palette: themeState.palette,
                    brightness: Brightness.dark,
                  ),
                  themeMode: themeState.themeMode,
                  builder: (context, child) {
                    Widget built = AppBlocListeners(
                      child: child ?? const SizedBox.shrink(),
                    );
                    built = botToast(context, built);
                    return built;
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Locale _resolveLocale(LocaleState state) {
    final localeId = state is LocaleLoaded ? state.localeId : 'th';
    final languageCode = localeId
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .split('-')
        .first;

    return languageCode == 'en'
        ? const Locale('en', 'GB')
        : const Locale('th', 'TH');
  }

  void _setSystemUIOverlay(bool isDark) {
    final navBarColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF4F7F6);
    final navBarDivider = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE8ECEB);

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: navBarColor,
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: navBarDivider,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: navBarColor,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: navBarDivider,
            ),
    );
  }
}
