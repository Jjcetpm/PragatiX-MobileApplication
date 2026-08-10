import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('initial state is unauthenticated', () {
      expect(authProvider.token, isNull);
      expect(authProvider.role, isNull);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('login updates state and notifies listeners', () {
      bool notified = false;
      authProvider.addListener(() {
        notified = true;
      });

      final mockUser = {'id': 1, 'name': 'Admin'};
      authProvider.login('test_token', 'ROLE_ADMIN', mockUser);

      expect(authProvider.token, 'test_token');
      expect(authProvider.role, 'ROLE_ADMIN');
      expect(authProvider.currentUser, mockUser);
      expect(authProvider.isAuthenticated, isTrue);
      expect(notified, isTrue);
    });

    test('logout clears state and notifies listeners', () {
      final mockUser = {'id': 1, 'name': 'Admin'};
      authProvider.login('test_token', 'ROLE_ADMIN', mockUser);

      bool notified = false;
      authProvider.addListener(() {
        notified = true;
      });

      authProvider.logout();

      expect(authProvider.token, isNull);
      expect(authProvider.role, isNull);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(notified, isTrue);
    });
  });
}
