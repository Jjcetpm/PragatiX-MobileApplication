import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/features/admin/pages/overview_tab.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  testWidgets('OverviewTab renders without throwing exceptions', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider();
    final mockAdminRepo = MockAdminRepository();
    
    when(() => mockAuth.currentUser).thenReturn({
      'roles': ['ROLE_SUPER_ADMIN'],
      'academicYear': 'FIRST_YEAR',
    });
    when(() => mockAuth.token).thenReturn('dummy_token');
    
    when(() => mockAdminRepo.getStats()).thenAnswer((_) async => {
      'totalStudents': 100,
      'teachersCount': 20,
      'totalDepartments': 5,
      'totalAlerts': 2,
      'pendingBadgeRequests': 1,
    });

    setupTestGetIt(adminRepo: mockAdminRepo);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        TestWrapper(
          mockAuthProvider: mockAuth,
          child: const OverviewTab(),
        ),
      );
      
      // Let it pump the loading state
      expect(tester.takeException(), isNull);
      
      // Pump until loaded
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Super Admin Overview'), findsOneWidget);
    });
  });
}
