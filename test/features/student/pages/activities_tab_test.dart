import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:pragatix/features/student/pages/activities_tab.dart';
import 'package:pragatix/features/student/screens/stage_details_screen.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;

class MockAuthProvider extends Mock implements AuthProvider {}
class MockAttendanceProvider extends Mock implements AttendanceProvider {}
class MockStudentProxyService extends Mock implements StudentProxyService {}
class FakeUri extends Fake implements Uri {}

void main() {
  late MockAuthProvider mockAuth;
  late MockAttendanceProvider mockAttendance;
  late MockStudentProxyService mockProxy;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockAuth = MockAuthProvider();
    mockAttendance = MockAttendanceProvider();
    mockProxy = MockStudentProxyService();

    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockAttendance.currentStreak).thenReturn(5);

    if (getIt.isRegistered<StudentProxyService>()) {
      getIt.unregister<StudentProxyService>();
    }
    getIt.registerSingleton<StudentProxyService>(mockProxy);
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
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
      ],
      child: const MaterialApp(
        home: ActivitiesTab(),
      ),
    );
  }

  group('ActivitiesTab Widget Tests', () {
    testWidgets('Renders top header, Your Progress card, and timeline stages correctly', (tester) async {
      when(() => mockProxy.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          '''
          {
            "success": true,
            "data": [
              {
                "id": 1,
                "name": "Stage 1",
                "displayOrder": 1,
                "stageStatus": "ACTIVE",
                "isCompleted": false,
                "isLocked": false,
                "overallCompletedSubgroups": 0,
                "overallTotalSubgroups": 3,
                "overallPercentage": 0.0
              },
              {
                "id": 2,
                "name": "Stage 2",
                "displayOrder": 2,
                "stageStatus": "LOCKED",
                "isCompleted": false,
                "isLocked": true,
                "overallCompletedSubgroups": 0,
                "overallTotalSubgroups": 3,
                "overallPercentage": 0.0
              },
              {
                "id": 3,
                "name": "Stage 3",
                "displayOrder": 3,
                "stageStatus": "LOCKED",
                "isCompleted": false,
                "isLocked": true,
                "overallCompletedSubgroups": 0,
                "overallTotalSubgroups": 3,
                "overallPercentage": 0.0
              }
            ]
          }
          ''',
          200,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Activities & Stages'), findsOneWidget);
      expect(find.textContaining('Complete subgroups to unlock'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // streak count

      // Your Progress Hero Card
      expect(find.text('Your Progress'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 / 9 Subgroups Completed'), findsOneWidget);
      expect(find.text('Keep going! Great things await you.'), findsOneWidget);

      // Verify illustrations are present
      expect(find.byType(Image), findsNWidgets(3));

      // Timeline Stages
      expect(find.text('Stage 1'), findsOneWidget);
      expect(find.text('Progress: 0% • 0 / 3 Subgroups'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);

      expect(find.text('Stage 2'), findsOneWidget);
      expect(find.text('Stage 3'), findsOneWidget);
      expect(find.text('Locked'), findsNWidgets(2));
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));

      // Motivation Banner
      expect(find.text('Keep Going!'), findsOneWidget);
      expect(find.textContaining('earn XP and\nunlock exciting rewards'), findsOneWidget);
      expect(find.byIcon(Icons.stars_rounded), findsOneWidget);
    });

    testWidgets('Dynamically renders any arbitrary number of stages (e.g. 5 stages)', (tester) async {
      when(() => mockProxy.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          '''
          {
            "success": true,
            "data": [
              {"id": 1, "name": "Stage 1", "displayOrder": 1, "stageStatus": "COMPLETED", "isCompleted": true, "overallCompletedSubgroups": 2, "overallTotalSubgroups": 2, "overallPercentage": 100.0},
              {"id": 2, "name": "Stage 2", "displayOrder": 2, "stageStatus": "ACTIVE", "isCompleted": false, "isLocked": false, "overallCompletedSubgroups": 1, "overallTotalSubgroups": 2, "overallPercentage": 50.0},
              {"id": 3, "name": "Stage 3", "displayOrder": 3, "stageStatus": "LOCKED", "isCompleted": false, "isLocked": true, "overallCompletedSubgroups": 0, "overallTotalSubgroups": 2, "overallPercentage": 0.0},
              {"id": 4, "name": "Stage 4", "displayOrder": 4, "stageStatus": "LOCKED", "isCompleted": false, "isLocked": true, "overallCompletedSubgroups": 0, "overallTotalSubgroups": 2, "overallPercentage": 0.0},
              {"id": 5, "name": "Stage 5", "displayOrder": 5, "stageStatus": "LOCKED", "isCompleted": false, "isLocked": true, "overallCompletedSubgroups": 0, "overallTotalSubgroups": 2, "overallPercentage": 0.0}
            ]
          }
          ''',
          200,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify all 5 stages exist
      expect(find.text('Stage 1'), findsOneWidget);
      expect(find.text('Stage 2'), findsOneWidget);
      expect(find.text('Stage 3'), findsOneWidget);
      expect(find.text('Stage 4'), findsOneWidget);
      expect(find.text('Stage 5'), findsOneWidget);

      // Verify dynamic hero progress (3 / 10 completed = 30%)
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('3 / 10 Subgroups Completed'), findsOneWidget);
    });

    testWidgets('Tapping unlocked Stage navigates to StageDetailsScreen', (tester) async {
      when(() => mockProxy.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          '''
          {
            "success": true,
            "data": [
              {
                "id": 1,
                "name": "Stage 1",
                "displayOrder": 1,
                "stageStatus": "ACTIVE",
                "isCompleted": false,
                "isLocked": false,
                "overallCompletedSubgroups": 0,
                "overallTotalSubgroups": 3,
                "overallPercentage": 0.0,
                "subgroups": []
              }
            ]
          }
          ''',
          200,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Stage 1
      await tester.tap(find.text('Stage 1'));
      await tester.pumpAndSettle();

      expect(find.byType(StageDetailsScreen), findsOneWidget);
    });
  });
}
