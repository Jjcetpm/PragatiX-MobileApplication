import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/admin/pages/admin_dashboard.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockBadgeProvider extends Mock implements BadgeProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockBadgeProvider mockBadge;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockBadge = MockBadgeProvider();

    when(() => mockAuth.token).thenReturn('fake-token');
    when(() => mockAuth.role).thenReturn('ADMIN');

    when(() => mockBadge.isLoading).thenReturn(false);
    when(() => mockBadge.adminCCBadgeRequests).thenReturn([
      {
        'id': 1,
        'badgeName': 'sample',
        'studentName': 'SHARUGESH',
        'regNo': '36',
        'status': 'PENDING',
      },
    ]);
    when(() => mockBadge.pendingAdminCCRequestsCount).thenReturn(1);
    when(() => mockBadge.adminBadges).thenReturn([]);
    when(() => mockBadge.fetchAdminCCBadgeRequests(any(), any())).thenAnswer((_) async {});
    when(() => mockBadge.fetchAdminBadges(any())).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<BadgeProvider>.value(value: mockBadge),
      ],
      child: const MaterialApp(
        home: AdminDashboard(),
      ),
    );
  }

  group('AdminDashboard Widget Tests', () {
    testWidgets('Renders bottom navigation bar with pending badge requests count badge on Requests tab', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Requests item with Badge label '1'
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
