import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/features/admin/services/admin_service.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('AdminService Tests', () {
    late MockAuthProvider mockAuthProvider;
    late AdminService adminService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      adminService = AdminService(mockAuthProvider);
    });

    test('initializes with correct AuthProvider', () {
      expect(adminService.authProvider, equals(mockAuthProvider));
    });

    // Note: Since AdminService uses the static top-level http.get/post methods instead of an injected http.Client,
    // intercepting the actual network calls without modifying the production code requires complex HttpOverrides.
    // In a fully testable architecture, http.Client should be injected via constructor.
  });
}
