import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/activity/providers/activity_completion_provider.dart';
import 'package:pragatix/features/student/screens/stage_details_screen.dart';
import 'package:pragatix/features/student/screens/activity_details_screen.dart';

class MockAttendanceProvider extends Mock implements AttendanceProvider {}
class MockAuthProvider extends Mock implements AuthProvider {}
class MockActivityCompletionProvider extends Mock implements ActivityCompletionProvider {}

void main() {
  late MockAttendanceProvider mockAttendance;
  late MockAuthProvider mockAuth;
  late MockActivityCompletionProvider mockCompletion;

  setUp(() {
    mockAttendance = MockAttendanceProvider();
    mockAuth = MockAuthProvider();
    mockCompletion = MockActivityCompletionProvider();

    when(() => mockAttendance.currentStreak).thenReturn(4);
    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockCompletion.loadMyRequests()).thenAnswer((_) async {});
    when(() => mockCompletion.myRequests).thenReturn([]);
    when(() => mockCompletion.isLoading).thenReturn(false);
  });

  Widget createWidgetUnderTest(Map<String, dynamic> stage) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<ActivityCompletionProvider>.value(value: mockCompletion),
      ],
      child: MaterialApp(
        home: StageDetailsScreen(stage: stage),
      ),
    );
  }

  group('StageDetailsScreen Tests', () {
    testWidgets('Renders top header, Stage Summary card, Subgroups, and numbered activities', (tester) async {
      final stageData = {
        'id': 1,
        'name': 'Stage 1 Details',
        'expectedXp': 200,
        'studentMustXp': 0,
        'studentIndividualXp': 0,
        'studentGroupXp': 0,
        'overallPercentage': 0.0,
        'stageStatus': 'ACTIVE',
        'subgroups': [
          {
            'name': 'Must',
            'threshold': 80,
            'activities': [
              {
                'id': 101,
                'activityName': 'Presentable attire',
                'rewardXp': 40,
                'awardedXp': 0,
                'status': 'PENDING',
              }
            ]
          },
          {
            'name': 'Individual',
            'threshold': 150,
            'activities': [
              {
                'id': 102,
                'activityName': 'Assignment Physics',
                'rewardXp': 10,
                'awardedXp': 0,
                'status': 'PENDING',
              },
              {
                'id': 103,
                'activityName': 'MS Word Document',
                'rewardXp': 50,
                'awardedXp': 0,
                'status': 'PENDING',
              }
            ]
          }
        ]
      };

      await tester.pumpWidget(createWidgetUnderTest(stageData));
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Stage Details'), findsOneWidget);
      expect(find.textContaining('Complete tasks and earn XP'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // streak
      expect(find.byType(Image), findsOneWidget); // mountain trail graphic

      // Stage Summary Hero Card
      expect(find.text('Stage Summary'), findsOneWidget);
      expect(find.text('ACTIVE •'), findsOneWidget);
      expect(find.text('0% Complete'), findsOneWidget);
      expect(find.text('Current XP'), findsOneWidget);
      expect(find.text('Expected XP'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('0 / 200 XP'), findsOneWidget);

      // Subgroup Headers
      expect(find.text('Must'), findsOneWidget);
      expect(find.text('0 / 80 XP'), findsOneWidget);
      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('0 / 150 XP'), findsOneWidget);

      // Activities and Number Badges
      expect(find.text('01'), findsOneWidget);
      expect(find.text('Presentable attire'), findsOneWidget);
      expect(find.text('Reward: 40 XP'), findsOneWidget);

      expect(find.text('02'), findsOneWidget);
      expect(find.text('Assignment Physics'), findsOneWidget);

      expect(find.text('03'), findsOneWidget);
      expect(find.text('MS Word Document'), findsOneWidget);

      // Bottom Complete all tasks Card
      expect(find.text('Complete all tasks'), findsOneWidget);
      expect(find.text('View Rewards'), findsOneWidget);
    });

    testWidgets('Tapping active activity navigates to ActivityDetailsScreen', (tester) async {
      final stageData = {
        'id': 1,
        'name': 'Stage 1',
        'expectedXp': 100,
        'studentMustXp': 0,
        'studentIndividualXp': 0,
        'studentGroupXp': 0,
        'overallPercentage': 0.0,
        'stageStatus': 'ACTIVE',
        'subgroups': [
          {
            'name': 'Individual',
            'threshold': 100,
            'activities': [
              {
                'id': 101,
                'activityName': 'Assignment Physics',
                'rewardXp': 10,
                'awardedXp': 0,
                'status': 'PENDING',
              }
            ]
          }
        ]
      };

      await tester.pumpWidget(createWidgetUnderTest(stageData));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assignment Physics'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityDetailsScreen), findsOneWidget);
    });

    testWidgets('Renders penalty activities with Penalty label and red badge', (tester) async {
      final stageData = {
        'id': 1,
        'name': 'Stage 1',
        'expectedXp': 100,
        'stageStatus': 'ACTIVE',
        'subgroups': [
          {
            'name': 'Must',
            'threshold': 50,
            'activities': [
              {
                'id': 201,
                'activityName': 'Late Attendance Penalty',
                'xpType': 'PENALTY',
                'penaltyXp': 20,
                'rewardXp': 0,
                'awardedXp': 0,
                'status': 'PENDING',
              }
            ]
          }
        ]
      };

      await tester.pumpWidget(createWidgetUnderTest(stageData));
      await tester.pumpAndSettle();

      expect(find.text('Late Attendance Penalty'), findsOneWidget);
      expect(find.text('Penalty: -20 XP'), findsOneWidget);
    });
  });
}
