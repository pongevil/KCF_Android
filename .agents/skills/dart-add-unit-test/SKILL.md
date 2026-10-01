---
name: dart-add-unit-test
description: Write and organize BS-Mobile unit tests with `flutter_test` and `mocktail`. Use when creating new logic or fixing bugs to ensure code remains correct and regression-free.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Fri, 24 Apr 2026 15:07:58 GMT
---
# Testing Dart and Flutter Applications

## Contents
- [Structuring Test Files](#structuring-test-files)
- [Writing Tests](#writing-tests)
- [Executing Tests](#executing-tests)
- [Test Implementation Workflow](#test-implementation-workflow)
- [Examples](#examples)

## Structuring Test Files
Organize test files to mirror the `lib` directory structure to maintain predictability.

* Place all test code within the `test` directory at the root of the package.
* Append `_test.dart` to the end of all test file names (e.g., `lib/src/utils.dart` should be tested in `test/src/utils_test.dart`).
* If writing integration tests, place them in an `integration_test` directory at the root of the package.

## Writing Tests
BS-Mobile is a Flutter package. Use `flutter_test` for the test runner/assertions and `mocktail` for test doubles; both are already declared in `pubspec.yaml`.

* Import `package:flutter_test/flutter_test.dart`.
* Group related tests using the `group()` function to provide shared context.
* Define individual test cases using the `test()` function.
* Validate outcomes using the `expect()` function alongside matchers (e.g., `equals()`, `isTrue`, `throwsA()`).
* Write asynchronous tests using standard `async`/`await` syntax. The test runner automatically waits for the `Future` to complete.
* Manage test setup and teardown using `setUp()` and `tearDown()` callbacks.
* If testing code that relies on dependency injection, extend `Mock` from `package:mocktail/mocktail.dart`; do not add Mockito or generated `.mocks.dart` files.

## Executing Tests
Use Flutter's test runner for this repository.

* Run a target file with `flutter test test/path/to/file_test.dart`.
* Run the unit/widget suite with `flutter test`.
* Run integration tests explicitly with `flutter test integration_test`.

## Test Implementation Workflow

Follow this sequential workflow when implementing new test suites. Copy the checklist to track your progress.

### Task Progress
- [ ] 1. Create the test file in the `test/` directory, ensuring the `_test.dart` suffix.
- [ ] 2. Import `package:flutter_test/flutter_test.dart` and the target library.
- [ ] 3. Define a `main()` function.
- [ ] 4. Initialize shared resources or mocks using `setUp()`.
- [ ] 5. Write `test()` cases grouped by functionality using `group()`.
- [ ] 6. Execute the test suite using the appropriate CLI command.
- [ ] 7. **Feedback Loop**: Run test -> Review stack trace for failures -> Fix implementation or assertions -> Re-run until passing.

## Examples

### Standard Unit Test Suite
Demonstrates grouping, setup, synchronous, and asynchronous testing.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bs_mobile/src/core/helpers/parse.dart';

void main() {
  group('Parse', () {
    test('parses an integer string', () {
      expect(Parse.parseInt('42'), equals(42));
    });
  });
}
```

### Mocking with Mocktail
Demonstrates configuring a handwritten mock object for dependency injection testing.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';

class MockConfigUrlRepository extends Mock
    implements ConfigUrlRepository {}

void main() {
  late MockConfigUrlRepository repository;

  setUp(() => repository = MockConfigUrlRepository());

  blocTest<ConfigUrlBloc, ConfigUrlState>(
    'emits success when connection succeeds',
    build: () {
      when(() => repository.testConnection(any()))
          .thenAnswer((_) async => true);
      return ConfigUrlBloc(repository);
    },
    act: (bloc) => bloc.add(
      const ConnectionTestRequested('https://api.example.com/'),
    ),
    expect: () => const [
      ConfigUrlLoading(),
      ConfigUrlSuccess('Connection Server Success'),
    ],
    verify: (_) => verify(
      () => repository.testConnection('https://api.example.com/'),
    ).called(1),
  );
}
```
