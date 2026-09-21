import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:pragatix/features/student/pages/point_review_tab.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;

class MockAuthProvider extends Mock implements AuthProvider {}
class MockXpProvider extends Mock implements XpProvider {}
class MockAttendanceProvider extends Mock implements AttendanceProvider {}
class MockStudentProxyService extends Mock implements StudentProxyService {}
class FakeUri extends Fake implements Uri {}

void main() {
  late MockAuthProvider mockAuth;
  late MockXpProvider mockXp;
  late MockAttendanceProvider mockAttendance;
  late MockStudentProxyService mockProxy;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockAuth = MockAuthProvider();
    mockXp = MockXpProvider();
    mockAttendance = MockAttendanceProvider();
    mockProxy = MockStudentProxyService();

    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockAttendance.currentStreak).thenReturn(5);

    if (getIt.isRegistered<StudentProxyService>()) {
      getIt.unregister<StudentProxyService>();
    }
    getIt.registerSingleton<StudentProxyService>(mockProxy);

    when(() => mockProxy.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        '{"success": true, "data": {"username": "717821F101", "stage": 1}}',
        200,
      ),
    );

    when(() => mockXp.fetchSummary(any(), any())).thenAnswer((_) async {});
    when(() => mockXp.fetchHistory(any(), any())).thenAnswer((_) async {});
    when(() => mockXp.fetchStages(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    if (getIt.isRegistered<StudentProxyService>()) {
      getIt.unregister<StudentProxyService>();
    }
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<XpProvider>.value(value: mockXp),
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
      ],
      child: const MaterialApp(
        home: PointReviewTab(),
      ),
    );
  }

  group('PointReviewTab XP Tracker Tests', () {
    testWidgets('Renders XP Summary cards and time filter correctly', (tester) async {
      when(() => mockXp.streaks).thenReturn([]);
      when(() => mockXp.stages).thenReturn([]);
      when(() => mockXp.xpByCategory).thenReturn({
        'individualXp': 120,
        'groupXp': 80,
        'mustXp': 40,
      });
      when(() => mockXp.history).thenReturn([
        {
          'activityName': 'Individual Task',
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'APPROVED',
          'xpPoints': 120,
          'category': 'SKILL',
          'stage': 1,
        },
        {
          'activityName': 'Team Task',
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'APPROVED',
          'xpPoints': 80,
          'category': 'GROUP',
          'stage': 1,
        },
        {
          'activityName': 'Must Task',
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'APPROVED',
          'xpPoints': 40,
          'category': 'MUST',
          'stage': 1,
        },
      ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify Headers
      expect(find.text('XP Summary'), findsOneWidget);

      // Verify Category Cards
      expect(find.text('Individual XP'), findsOneWidget);
      expect(find.text('120 XP'), findsOneWidget);

      expect(find.text('Group XP'), findsOneWidget);
      expect(find.text('80 XP'), findsOneWidget);

      expect(find.text('Must XP'), findsOneWidget);
      expect(find.text('40 XP'), findsOneWidget);

      // Verify Tags
      expect(find.text('HIGH'), findsNWidgets(2));
      expect(find.text('MANDATORY'), findsOneWidget);
    });

    testWidgets('Stage 2 student starts with 0 XP when history belongs to Stage 1', (tester) async {
      when(() => mockProxy.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          '{"success": true, "data": {"username": "717821F101", "stage": 2}}',
          200,
        ),
      );

      when(() => mockXp.streaks).thenReturn([]);
      when(() => mockXp.stages).thenReturn([]);
      when(() => mockXp.xpByCategory).thenReturn({
        'individualXp': 0,
        'groupXp': 0,
        'mustXp': 0,
      });
      when(() => mockXp.history).thenReturn([
        {
          'activityName': 'Stage 1 Task',
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'APPROVED',
          'xpPoints': 240,
          'category': 'INDIVIDUAL',
          'stage': 1,
        },
        {
          'activityName': 'Stage 1 Group Task',
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'APPROVED',
          'xpPoints': 200,
          'category': 'GROUP',
          'stage': 1,
        },
      ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // For Stage 2, Stage 1 transactions are excluded, so it starts at 0 XP
      expect(find.text('0 XP'), findsNWidgets(3));
    });

    testWidgets('Renders XP Submission History cards with details, status, and staff name', (tester) async {
      when(() => mockXp.streaks).thenReturn([]);
      when(() => mockXp.stages).thenReturn([]);
      when(() => mockXp.xpByCategory).thenReturn({
        'individualXp': 120,
        'groupXp': 80,
        'mustXp': 40,
      });
      when(() => mockXp.history).thenReturn([
        {
          'activityName': 'Captain Weekly Reward - Week 4',
          'submittedAt': '2026-08-27T10:00:00.000Z',
          'status': 'APPROVED',
          'approvedBy': 'Prof. John',
          'xpPoints': 100,
          'category': 'LEADERSHIP',
          'description': 'Weekly leadership coordination tasks completed',
        }
      ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify History Header
      expect(find.text('XP Submission History'), findsOneWidget);

      // Verify History Item
      expect(find.text('Captain Weekly Reward - Week 4'), findsOneWidget);
      expect(find.text('2026 08 27'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('• Prof. John'), findsOneWidget);
      expect(find.text('+100 XP'), findsOneWidget);
    });

    testWidgets('Tapping history item opens submission details bottom sheet with awarding staff name', (tester) async {
      when(() => mockXp.streaks).thenReturn([]);
      when(() => mockXp.stages).thenReturn([]);
      when(() => mockXp.xpByCategory).thenReturn({});
      when(() => mockXp.history).thenReturn([
        {
          'activityName': 'Captain Weekly Reward - Week 4',
          'submittedAt': '2026-08-27T10:00:00.000Z',
          'status': 'APPROVED',
          'approvedBy': 'Prof. John',
          'xpPoints': 100,
          'category': 'LEADERSHIP',
          'description': 'Weekly leadership coordination tasks completed',
        }
      ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the history item
      await tester.tap(find.text('Captain Weekly Reward - Week 4'));
      await tester.pumpAndSettle();

      // Verify details modal content
      expect(find.text('Category: LEADERSHIP'), findsOneWidget);
      expect(find.text('Awarded by: '), findsOneWidget);
      expect(find.text('Prof. John'), findsOneWidget);
      expect(find.text('Weekly leadership coordination tasks completed'), findsOneWidget);
    });
  });
}
