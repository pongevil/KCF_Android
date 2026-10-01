import 'package:bs_mobile/src/global/blocs/version/version_bloc.dart';
import 'package:bs_mobile/src/global/models/api_base_response.dart';
import 'package:bs_mobile/src/global/blocs/version/repository/version_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVersionRepository extends Mock implements VersionRepository {}

void main() {
  late MockVersionRepository repository;

  setUp(() {
    repository = MockVersionRepository();
  });

  blocTest<VersionBloc, VersionState>(
    'emits [VersionCheckInProgress, VersionUpToDate] when no update',
    build: () {
      when(() => repository.fetchVersionStatus()).thenAnswer(
        (_) async => ApiBaseResponse(messageCode: 0, messageText: 'ok'),
      );
      return VersionBloc(repository);
    },
    act: (bloc) => bloc.add(VersionCheckEvent()),
    expect: () => [isA<VersionCheckInProgress>(), isA<VersionUpToDate>()],
  );

  blocTest<VersionBloc, VersionState>(
    'emits VersionUpdateAvailable when update exists',
    build: () {
      when(() => repository.fetchVersionStatus()).thenAnswer(
        (_) async => ApiBaseResponse(
          messageCode: 0,
          messageText: 'New version',
          isUpdateAvailable: true,
        ),
      );
      return VersionBloc(repository);
    },
    act: (bloc) => bloc.add(VersionCheckEvent()),
    expect: () => [
      isA<VersionCheckInProgress>(),
      isA<VersionUpdateAvailable>()
          .having((s) => s.message, 'message', 'New version')
          .having((s) => s.isForceUpdate, 'isForceUpdate', false),
    ],
  );

  blocTest<VersionBloc, VersionState>(
    'emits VersionUpdateAvailable with isForceUpdate when force update',
    build: () {
      when(() => repository.fetchVersionStatus()).thenAnswer(
        (_) async => ApiBaseResponse(
          messageCode: 0,
          messageText: 'กรุณาอัปเดตแอปก่อนใช้งาน',
          isUpdateAvailable: true,
          isForceUpdate: true,
        ),
      );
      return VersionBloc(repository);
    },
    act: (bloc) => bloc.add(VersionCheckEvent()),
    expect: () => [
      isA<VersionCheckInProgress>(),
      isA<VersionUpdateAvailable>()
          .having((s) => s.message, 'message', 'กรุณาอัปเดตแอปก่อนใช้งาน')
          .having((s) => s.isForceUpdate, 'isForceUpdate', true),
    ],
  );
}
