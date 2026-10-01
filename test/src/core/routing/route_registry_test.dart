import 'package:bs_mobile/src/core/routing/route_registry.dart';
import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteRegistry', () {
    test('normalize adds leading slash', () {
      expect(RouteRegistry.normalize('home'), '/home');
      expect(RouteRegistry.normalize('/home'), '/home');
    });

    test('isRegistered returns true for known menu paths', () {
      expect(RouteRegistry.isRegistered('/home'), isTrue);
      expect(RouteRegistry.isRegistered('/settings'), isTrue);
      expect(RouteRegistry.isRegistered('/outbound_main'), isTrue);
    });

    test('isRegistered returns false for unknown paths', () {
      expect(RouteRegistry.isRegistered('/unknown'), isFalse);
      expect(RouteRegistry.isRegistered(null), isFalse);
    });

    test('registeredPaths includes all Routes constants', () {
      expect(RouteRegistry.registeredPaths, contains(Routes.settings));
      expect(RouteRegistry.registeredPaths, contains(Routes.configRfid));
    });
  });
}
