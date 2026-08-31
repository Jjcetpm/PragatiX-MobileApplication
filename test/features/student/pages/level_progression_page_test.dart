import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/student/pages/level_progression_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockXpProvider extends Mock implements XpProvider {}
class MockAttendanceProvider extends Mock implements AttendanceProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockXpProvider mockXp;
  late MockAttendanceProvider mockAttendance;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockXp = MockXpProvider();
    mockAttendance = MockAttendanceProvider();

    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockAuth.role).thenReturn('STUDENT');
    when(() => mockAttendance.currentStreak).thenReturn(5);

    when(() => mockXp.isLoading).thenReturn(false);
    when(() => mockXp.fetchProgression(any())).thenAnswer((_) async {});
    when(() => mockXp.progression).thenReturn({
      'totalXp': 540,
      'currentLevel': 3,
      'currentLevelName': 'Innovator',
      'currentLevelMinXp': 501,
      'currentLevelMaxXp': 1500,
      'remainingXp': 961,
      'progressPercentage': 36.0,
      'unlockedLevels': [
        {
          'levelNumber': 1,
          'title': 'Explorer',
          'xpMin': 0,
          'xpMax': 100,
          'primaryObjective': 'Build participation habits',
        },
        {
          'levelNumber': 2,
          'title': 'Builder',
          'xpMin': 101,
          'xpMax': 500,
          'primaryObjective': 'Develop consistency & discipline',
        },
        {
          'levelNumber': 3,
          'title': 'Innovator',
          'xpMin': 501,
          'xpMax': 1500,
          'primaryObjective': 'Build technical & collaborative skills',
        },
      ],
      'lockedLevels': [
        {
          'levelNumber': 4,
          'title': 'Leader',
          'xpMin': 1501,
          'xpMax': 3000,
          'primaryObjective': 'Lead projects and inspire peers',
        },
        {
          'levelNumber': 5,
          'title': 'Visionary',
          'xpMin': 3001,
          'xpMax': 5000,
          'primaryObjective': 'Create impact and drive innovation',
        },
      ],
    });
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<XpProvider>.value(value: mockXp),
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
      ],
      child: const MaterialApp(
        home: LevelProgressionPage(),
      ),
    );
  }

  testWidgets('LevelProgressionPage renders hero level card, summary metrics, timeline and trophy banner', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // App Bar
    expect(find.text('Level Progression'), findsOneWidget);

    // Hero Level Card
    expect(find.text('CURRENT LEVEL'), findsOneWidget);
    expect(find.text('Lvl 3: Innovator'), findsOneWidget);
    expect(find.text('540 XP Points'), findsOneWidget);
    expect(find.text('Target: 1500 XP'), findsOneWidget);
    expect(find.text('Remaining: 961 XP'), findsOneWidget);
    expect(find.text('36%'), findsOneWidget);

    // 4-Column Dark Summary Box
    expect(find.text('Current XP'), findsOneWidget);
    expect(find.text('Target XP'), findsOneWidget);
    expect(find.text('XP to next level'), findsOneWidget);
    expect(find.text('Levels Completed'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);

    // Section Header
    expect(find.text('Your Progress Journey'), findsOneWidget);
    expect(find.text('Complete levels and earn XP to reach new heights!'), findsOneWidget);

    // Timeline Levels
    expect(find.text('Level 1: Explorer'), findsOneWidget);
    expect(find.text('Level 2: Builder'), findsOneWidget);
    expect(find.text('Level 3: Innovator'), findsOneWidget);
    expect(find.text('Level 4: Leader'), findsOneWidget);
    expect(find.text('Level 5: Visionary'), findsOneWidget);

    // Status Pills
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Current Level'), findsOneWidget);
    expect(find.text('Locked'), findsNWidgets(2));

    // Bottom Golden Trophy Motivation Banner
    expect(find.text('Keep Going!'), findsOneWidget);
    expect(find.text('View Rewards'), findsOneWidget);
  });
}
