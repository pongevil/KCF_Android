---
name: dart-generate-test-mocks
description: Define handwritten mock objects for BS-Mobile dependencies using `package:mocktail`. Use when unit testing classes that depend on APIs, storage, or databases.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Fri, 24 Apr 2026 15:13:58 GMT
---
# Testing and Mocking Dart Applications

## Contents
- [Structuring Code for Testability](#structuring-code-for-testability)
- [Managing Dependencies](#managing-dependencies)
- [Defining Mocks](#defining-mocks)
- [Implementing Unit Tests](#implementing-unit-tests)
- [Workflow: Creating and Running Mocked Tests](#workflow-creating-and-running-mocked-tests)
- [Examples](#examples)

## Structuring Code for Testability
Design Dart classes to support dependency injection. Isolate complex external dependencies (like API clients or databases) so they can be replaced with mock objects during testing.

- Inject external services (e.g., `http.Client`) through class constructors.
- Represent URLs strictly as `Uri` objects using `Uri.parse(string)`.
- Utilize Dart's object-oriented features (classes, mixins) to define clear interfaces for external interactions.

## Managing Dependencies
BS-Mobile already declares `flutter_test` and `mocktail` in `pubspec.yaml`.

- Do not add Mockito, annotations, or generated `.mocks.dart` files.
- Import `package:flutter_test/flutter_test.dart` for tests and assertions.
- Import `package:mocktail/mocktail.dart` for `Mock`, `when`, `verify`, and matchers.
- Prefer mocking a repository or project adapter rather than a third-party client deep inside the stack.

## Defining Mocks
Mocktail uses handwritten mock classes and does not require code generation.

```dart
class MockFeatureRepository extends Mock implements FeatureRepository {}
```

For `any()` with a custom non-nullable argument type, define a small fake and register it once in `setUpAll`:

```dart
class FakeFeatureRequest extends Fake implements FeatureRequest {}

setUpAll(() {
  registerFallbackValue(FakeFeatureRequest());
});
```

## Implementing Unit Tests
Isolate the system under test with handwritten Mocktail mocks. Use `flutter_test` to structure the test suite.

- **Stubbing:** Configure mock behavior before interacting with the system under test.
  - Use `when(() => mock.method()).thenReturn(value)` for synchronous methods.
  - **CRITICAL:** Always use `thenAnswer((_) async => value)` for methods returning a `Future` or `Stream`. Never use `thenReturn` for asynchronous returns.
- **Verification:** Assert that the system under test interacted with the mock object correctly.
  - Use `verify(() => mock.method()).called(1)` to check exact invocation counts.
  - Use argument matchers like `any()`, `any(named: 'name')`, or `captureAny()` for flexible verification.

## Workflow: Creating and Running Mocked Tests

Use the following checklist to implement and verify mocked unit tests.

### Task Progress
- [ ] 1. Identify the external dependency to mock (e.g., `http.Client`).
- [ ] 2. Inject the dependency into the target class constructor.
- [ ] 3. Create a test file mirroring the `lib/` path and define `class MockDependency extends Mock implements Dependency {}`.
- [ ] 4. Register fallback values in `setUpAll()` only when custom argument matchers require them.
- [ ] 5. Write the test cases using `group()` and `test()`.
- [ ] 6. Stub required behaviors using closure-based `when(() => ...)`.
- [ ] 7. Execute the target method.
- [ ] 8. Verify interactions using `verify(() => ...)` and assert outcomes using `expect()`.
- [ ] 9. Run the target test with `flutter test <path>`.

### Feedback Loop: Test Failures
If tests fail:
1. **Run validator:** Execute `flutter test <path>`.
2. **Review errors:** Check for missing stubs, mismatched argument matchers, or missing fallback values.
3. **Fix:**
   - If `any()` rejects a custom type, register a `Fake` fallback value.
   - If an async stub throws an `ArgumentError`, change `thenReturn` to `thenAnswer`.
4. Repeat until all tests pass.

## Examples

### Mocktail Testing Example

**1. System under test**

```dart
abstract class DataGateway {
  Future<String> fetch(Uri uri);
}

class DataService {
  DataService(this.gateway);

  final DataGateway gateway;

  Future<String> fetchData(String url) {
    return gateway.fetch(Uri.parse(url));
  }
}
```

**2. Test implementation**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataGateway extends Mock implements DataGateway {}

void main() {
  group('DataService', () {
    late MockDataGateway gateway;
    late DataService service;

    setUp(() {
      gateway = MockDataGateway();
      service = DataService(gateway);
    });

    test('returns data from the gateway', () async {
      final uri = Uri.parse('https://api.example.com/data');
      when(() => gateway.fetch(uri)).thenAnswer((_) async => 'Success');

      final result = await service.fetchData(uri.toString());

      expect(result, 'Success');
      verify(() => gateway.fetch(uri)).called(1);
    });

    test('forwards gateway failures', () async {
      final uri = Uri.parse('https://api.example.com/data');
      when(() => gateway.fetch(uri)).thenAnswer(
        (_) async => throw Exception('Not found'),
      );

      await expectLater(service.fetchData(uri.toString()), throwsException);
    });
  });
}
```
