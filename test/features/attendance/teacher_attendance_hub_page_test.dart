import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/features/attendance/pages/teacher_attendance_hub_page.dart';
import 'package:pragatix/features/attendance/pages/teacher_attendance_tab.dart';
import 'package:pragatix/features/attendance/pages/admin_attendance_tab.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  testWidgets('TeacherAttendanceHubPage renders and switches between Mark and Matrix modes', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider();
    final mockAdminRepo = MockAdminRepository();

    when(() => mockAuth.currentUser).thenReturn({
      'roles': ['ROLE_TEACHER', 'ROLE_CLASS_COORDINATOR'],
      'subRoles': ['CC'],
      'department': 'CSE',
      'year': 'FIRST_YEAR',
    });
    when(() => mockAuth.token).thenReturn('mock_token');
    when(() => mockAuth.isSuperAdmin).thenReturn(false);

    when(() => mockAdminRepo.getAssignedYears()).thenAnswer((_) async => []);
    when(() => mockAdminRepo.getDepartments(all: any(named: 'all'))).thenAnswer((_) async => []);

    setupTestGetIt(adminRepo: mockAdminRepo, authProvider: mockAuth);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        TestWrapper(
          mockAuthProvider: mockAuth,
          child: const TeacherAttendanceHubPage(subRoles: ['CC']),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Check Header title and switch pills exist
      expect(find.text('Attendance Management'), findsOneWidget);
      expect(find.text('Mark Attendance'), findsOneWidget);
      expect(find.text('History Matrix'), findsOneWidget);

      // Initially Mark Attendance is active
      expect(find.byType(TeacherAttendanceTab), findsOneWidget);

      // Tap History Matrix
      await tester.tap(find.text('History Matrix'));
      await tester.pump(const Duration(seconds: 2));

      // Now AdminAttendanceTab is active
      expect(find.byType(AdminAttendanceTab), findsOneWidget);

      // Tap back to Mark Attendance
      await tester.tap(find.text('Mark Attendance'));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TeacherAttendanceTab), findsOneWidget);
    });
  });
}
