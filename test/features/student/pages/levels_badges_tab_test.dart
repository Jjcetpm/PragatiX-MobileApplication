import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/student/pages/levels_badges_tab.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockBadgeProvider extends Mock implements BadgeProvider {}
class MockXpProvider extends Mock implements XpProvider {}
class MockAttendanceProvider extends Mock implements AttendanceProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockBadgeProvider mockBadge;
  late MockXpProvider mockXp;
  late MockAttendanceProvider mockAttendance;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockBadge = MockBadgeProvider();
    mockXp = MockXpProvider();
    mockAttendance = MockAttendanceProvider();

    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockAttendance.currentStreak).thenReturn(4);

    when(() => mockBadge.isLoading).thenReturn(false);
    when(() => mockXp.isLoading).thenReturn(false);

    when(() => mockBadge.fetchMyBadges(any())).thenAnswer((_) async {});
    when(() => mockBadge.fetchMyBadgeRequests(any())).thenAnswer((_) async {});
    when(() => mockBadge.fetchAllBadges(any())).thenAnswer((_) async {});
    when(() => mockXp.fetchProgression(any())).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<BadgeProvider>.value(value: mockBadge),
        ChangeNotifierProvider<XpProvider>.value(value: mockXp),
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
      ],
      child: const MaterialApp(
        home: LevelsBadgesTab(),
      ),
    );
  }

  group('LevelsBadgesTab Widget Tests', () {
    testWidgets('Renders dark header, tier tabs, hero progress card, badges grid, and trophy banner', (tester) async {
      when(() => mockBadge.availableBadges).thenReturn([
        {
          'id': 1,
          'name': 'Attendance Warrior',
          'description': 'Maintain 100% attendance for 7 consecutive days',
          'tier': 'Foundation',
          'rarity': 'Common',
        },
        {
          'id': 2,
          'name': 'Participation Star',
          'description': 'Participate in 10 activities',
          'tier': 'Foundation',
          'rarity': 'Rare',
        },
        {
          'id': 3,
          'name': 'Punctuality Pro',
          'description': 'Be on time for 10 consecutive sessions',
          'tier': 'Foundation',
          'rarity': 'Uncommon',
        },
      ]);
      when(() => mockBadge.earnedBadges).thenReturn([]);
      when(() => mockBadge.myBadgeRequests).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('Unlock badges and showcase your achievements'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // streak

      // Tier Tabs
      expect(find.text('Foundation'), findsAtLeastNWidgets(1));
      expect(find.text('Achievement'), findsOneWidget);
      expect(find.text('Excellence'), findsOneWidget);
      expect(find.text('Elite'), findsOneWidget);
      expect(find.text('Legacy'), findsOneWidget);

      // Hero Progress Card
      expect(find.text('Foundation Progress'), findsOneWidget);
      expect(find.text('0'), findsAtLeastNWidgets(1));
      expect(find.text('Badges Unlocked'), findsOneWidget);
      expect(find.text('0% Completed'), findsOneWidget);

      // Badges Grid
      expect(find.text('Attendance Warrior'), findsOneWidget);
      expect(find.text('Participation Star'), findsOneWidget);
      expect(find.text('Punctuality Pro'), findsOneWidget);
      expect(find.text('LOCKED'), findsNWidgets(3));

      // Bottom Trophy Motivation Banner
      expect(find.text('Collect all Foundation badges'), findsOneWidget);
      expect(find.text('View All Badges'), findsOneWidget);
    });

    testWidgets('Displays CLAIMED status when a badge is earned', (tester) async {
      when(() => mockBadge.availableBadges).thenReturn([
        {
          'id': 1,
          'name': 'Attendance Warrior',
          'description': 'Maintain 100% attendance for 7 consecutive days',
          'tier': 'Foundation',
          'rarity': 'Common',
        },
      ]);
      when(() => mockBadge.earnedBadges).thenReturn([
        {
          'badgeId': 1,
          'earnedAt': '2026-08-27T10:00:00Z',
        }
      ]);
      when(() => mockBadge.myBadgeRequests).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('CLAIMED'), findsOneWidget);
      expect(find.text('100% Completed'), findsOneWidget);
    });

    testWidgets('Tapping badge opens detail bottom sheet', (tester) async {
      when(() => mockBadge.availableBadges).thenReturn([
        {
          'id': 1,
          'name': 'Attendance Warrior',
          'description': 'Maintain 100% attendance for 7 consecutive days',
          'tier': 'Foundation',
          'rarity': 'Common',
          'proofRequired': false,
        },
      ]);
      when(() => mockBadge.earnedBadges).thenReturn([]);
      when(() => mockBadge.myBadgeRequests).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attendance Warrior'));
      await tester.pumpAndSettle();

      // Modal contents
      expect(find.text('Badge Approval Workflow (6 Steps)'), findsOneWidget);
      expect(find.text('Submit Badge Claim'), findsOneWidget);
    });
  });
}
