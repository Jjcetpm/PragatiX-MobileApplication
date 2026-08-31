import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/leaderboard/services/leaderboard_service.dart';
import 'package:pragatix/features/leaderboard/pages/shared_leaderboard_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockXpProvider extends Mock implements XpProvider {}
class MockAttendanceProvider extends Mock implements AttendanceProvider {}
class MockLeaderboardService extends Mock implements LeaderboardService {}

void main() {
  late MockAuthProvider mockAuth;
  late MockXpProvider mockXp;
  late MockAttendanceProvider mockAttendance;
  late MockLeaderboardService mockLeaderboard;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockXp = MockXpProvider();
    mockAttendance = MockAttendanceProvider();
    mockLeaderboard = MockLeaderboardService();

    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockAuth.role).thenReturn('STUDENT');
    when(() => mockAuth.currentUser).thenReturn({
      'id': '615',
      'fullName': 'SHARUGESH',
      'regNo': '36',
    });
    when(() => mockAttendance.currentStreak).thenReturn(5);
    when(() => mockXp.totalXp).thenReturn(540);

    if (getIt.isRegistered<LeaderboardService>()) {
      getIt.unregister<LeaderboardService>();
    }
    getIt.registerSingleton<LeaderboardService>(mockLeaderboard);

    when(() => mockLeaderboard.getFilters(
          yearId: any(named: 'yearId'),
          departmentId: any(named: 'departmentId'),
        )).thenAnswer((_) async => {
          'years': [{'id': '2024', 'name': '2024 Batch'}],
          'departments': [{'id': '1', 'name': 'Computer Science'}],
          'sections': [{'id': '1', 'name': 'A - 2024 Batch'}],
        });

    when(() => mockLeaderboard.getLeaderboard(
          yearId: any(named: 'yearId'),
          departmentId: any(named: 'departmentId'),
          sectionId: any(named: 'sectionId'),
        )).thenAnswer((_) async => [
          {
            'regNo': '36',
            'fullName': 'SHARUGESH',
            'totalXp': 540,
            'departmentName': 'Computer Science & Engineering',
            'year': '1',
            'section': 'A',
          },
          {
            'regNo': '2',
            'fullName': 'Arun Kumar',
            'totalXp': 300,
            'departmentName': 'Computer Science & Engineering',
            'year': '1',
            'section': 'A',
          },
          {
            'regNo': '3',
            'fullName': 'Abhishek Kapoor',
            'totalXp': 280,
            'departmentName': 'Computer Science & Engineering',
            'year': '1',
            'section': 'A',
          },
          {
            'regNo': '4',
            'fullName': 'Abhishek Gupta',
            'totalXp': 200,
            'departmentName': 'Computer Science & Engineering',
            'year': '1',
            'section': 'A',
          },
          {
            'regNo': '5',
            'fullName': 'Abhishek Nair',
            'totalXp': 200,
            'departmentName': 'Computer Science & Engineering',
            'year': '1',
            'section': 'A',
          },
        ]);
  });

  tearDown(() {
    if (getIt.isRegistered<LeaderboardService>()) {
      getIt.unregister<LeaderboardService>();
    }
  });

  Widget createWidgetUnderTest({String? role, bool showFilters = true, bool? showYearFilter}) {
    if (role != null) {
      when(() => mockAuth.role).thenReturn(role);
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<XpProvider>.value(value: mockXp),
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
      ],
      child: MaterialApp(
        home: SharedLeaderboardPage(
          title: 'Leaderboard',
          showFilters: showFilters,
          showYearFilter: showYearFilter ?? (role == 'SUPER_ADMIN'),
          showDepartmentFilter: true,
          showSectionFilter: true,
          showCurrentUserRank: true,
        ),
      ),
    );
  }

  testWidgets('SharedLeaderboardPage renders student view WITH Department and Section filters (Year hidden)', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(showFilters: true, showYearFilter: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Top App Bar
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Compete • Earn • Lead'), findsOneWidget);

    // Department & Section filters should be present on student view
    expect(find.text('Department'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    // Year filter should NOT be present on student view
    expect(find.text('Year'), findsNothing);

    // Podium
    expect(find.text('Top Performers (Sorted by Total XP)'), findsOneWidget);
    expect(find.text('SHARUGESH'), findsNWidgets(2));
    expect(find.text('Arun Kumar'), findsOneWidget);
    expect(find.text('Abhishek Kapoor'), findsOneWidget);

    // All Students list
    expect(find.text('All Students'), findsOneWidget);
    expect(find.text('Abhishek Gupta'), findsOneWidget);
    expect(find.text('Abhishek Nair'), findsOneWidget);

    // Bottom Sticky Rank Bar
    expect(find.text('Your Rank'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('540 XP'), findsNWidgets(2));
  });

  testWidgets('SharedLeaderboardPage renders super admin view with Year, Department, and Section filters', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      role: 'SUPER_ADMIN',
      showFilters: true,
      showYearFilter: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // For Super Admin with filters enabled
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    // Batch suffix should NOT be in the section name
    expect(find.text('A - 2024 Batch'), findsNothing);
  });
}
