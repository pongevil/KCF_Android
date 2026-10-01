import 'package:bs_mobile/src/core/app_config/app_config_repository.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_repository.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_service.dart';
import 'package:bs_mobile/src/core/localization/locale_repository.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_error_notifier.dart';
import 'package:bs_mobile/src/core/network/device_info_provider.dart';
import 'package:bs_mobile/src/core/network/session_expired_handler.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_handler.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_repository.dart';
import 'package:bs_mobile/src/core/push_notification/push_notification_service.dart';
import 'package:bs_mobile/src/core/routing/app_router.dart';
import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:bs_mobile/src/global/blocs/app_config/app_config_bloc.dart';
import 'package:bs_mobile/src/global/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:bs_mobile/src/global/blocs/combobox/combobox_bloc.dart';
import 'package:bs_mobile/src/global/blocs/combobox/repository/combobox_repository.dart';
import 'package:bs_mobile/src/global/blocs/locale/locale_bloc.dart';

import 'package:bs_mobile/src/global/blocs/network/network_bloc.dart';
import 'package:bs_mobile/src/global/blocs/push_notification/push_notification_bloc.dart';
import 'package:bs_mobile/src/global/blocs/theme/theme_bloc.dart';
import 'package:bs_mobile/src/global/blocs/version/version_bloc.dart';

import 'package:bs_mobile/src/global/blocs/version/repository/version_repository.dart';
import 'package:bs_mobile/src/features/ai/repository/ai_chat_repository.dart';
import 'package:bs_mobile/src/features/ai/presentation/bloc/ai_chat_bloc.dart';
import 'package:bs_mobile/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bs_mobile/src/features/auth/repository/auth_repository.dart';
import 'package:bs_mobile/src/features/config_rfid/presentation/bloc/config_rfid_bloc.dart';
import 'package:bs_mobile/src/features/config_rfid/service/rfid_device_service.dart';
import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bs_mobile/src/features/home/presentation/bloc/menu_bloc.dart';
import 'package:bs_mobile/src/features/home/presentation/cubit/drawer_profile_cubit.dart';
import 'package:bs_mobile/src/features/home/repository/menu_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<ApiClient>()) return;

  getIt.registerLazySingleton<DeviceInfoProvider>(
    () => const DeviceInfoProvider(),
  );
  getIt.registerLazySingleton<ApiErrorNotifier>(() => ApiErrorNotifier());
  getIt.registerLazySingleton<GoRouter>(AppRouter.create);
  getIt.registerLazySingleton<SessionExpiredHandler>(
    () => SessionExpiredHandler(
      navigateToLogin: () => getIt<GoRouter>().go(Routes.login),
    ),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      errorNotifier: getIt<ApiErrorNotifier>(),
      deviceInfoProvider: getIt<DeviceInfoProvider>(),
      sessionExpiredHandler: getIt<SessionExpiredHandler>(),
    ),
  );

  getIt.registerLazySingleton<BarcodeFormatRepository>(
    () => BarcodeFormatRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BarcodeFormatService>(
    () => BarcodeFormatService(getIt<BarcodeFormatRepository>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<VersionRepository>(
    () => VersionRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PushNotificationHandler>(
    () => PushNotificationHandler(),
  );
  getIt.registerLazySingleton<PushNotificationRepository>(
    () => PushNotificationRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      handler: getIt<PushNotificationHandler>(),
      repository: getIt<PushNotificationRepository>(),
    ),
  );

  getIt.registerFactory<NetworkBloc>(() => NetworkBloc());
  getIt.registerLazySingleton<ComboboxRepository>(
    () => ComboboxRepository(getIt<ApiClient>()),
  );
  getIt.registerFactory<ComboboxBloc>(
    () => ComboboxBloc(comboboxRepository: getIt<ComboboxRepository>()),
  );
  getIt.registerFactory<LocaleBloc>(
    () => LocaleBloc(LocaleRepository(getIt<ApiClient>())),
  );
  getIt.registerLazySingleton<AiChatRepository>(
    () => AiChatRepository(getIt<ApiClient>()),
  );
  getIt.registerFactory<AiChatBloc>(
    () => AiChatBloc(repository: getIt<AiChatRepository>()),
  );
  getIt.registerFactory<AppConfigBloc>(
    () => AppConfigBloc(AppConfigRepository(getIt<ApiClient>())),
  );
  getIt.registerLazySingleton<BluetoothBloc>(() => BluetoothBloc());
  getIt.registerFactory<ThemeBloc>(() => ThemeBloc());
  getIt.registerFactory<VersionBloc>(
    () => VersionBloc(getIt<VersionRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<MenuBloc>(
    () => MenuBloc(MenuRepository(getIt<ApiClient>())),
  );
  getIt.registerLazySingleton<ConfigUrlRepository>(
    () => ConfigUrlRepository(getIt<ApiClient>()),
  );
  getIt.registerFactory<ConfigUrlBloc>(
    () => ConfigUrlBloc(getIt<ConfigUrlRepository>()),
  );
  getIt.registerLazySingleton<RfidDeviceService>(() => RfidDeviceService());
  getIt.registerFactory<ConfigRfidBloc>(
    () => ConfigRfidBloc(getIt<RfidDeviceService>()),
  );
  getIt.registerFactory<DrawerProfileCubit>(() => DrawerProfileCubit());
  getIt.registerFactory<PushNotificationBloc>(
    () => PushNotificationBloc(getIt<PushNotificationService>()),
  );
}
