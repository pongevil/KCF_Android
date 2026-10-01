import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/global/blocs/combobox/combobox_bloc.dart';
import 'package:bs_mobile/src/global/blocs/combobox/repository/combobox_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('registers and resolves ComboboxRepository and ComboboxBloc', () async {
    await configureDependencies();

    expect(getIt.isRegistered<ComboboxRepository>(), isTrue);
    expect(getIt.isRegistered<ComboboxBloc>(), isTrue);
    expect(getIt<ComboboxRepository>(), isA<ComboboxRepository>());

    final bloc = getIt<ComboboxBloc>();
    addTearDown(bloc.close);
    expect(bloc, isA<ComboboxBloc>());
  });
}
