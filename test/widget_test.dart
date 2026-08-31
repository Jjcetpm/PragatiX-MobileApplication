import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/mocks.dart';
import 'helpers/test_wrapper.dart';

void main() {
  testWidgets('App renders login page when unauthenticated', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final mockAuth = MockAuthProvider();
    final mockAuthRepo = MockAuthRepository();
    when(() => mockAuth.isAuthenticated).thenReturn(false);
    when(() => mockAuth.currentUser).thenReturn(null);
    setupTestGetIt(authRepo: mockAuthRepo);

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        TestWrapper(
          mockAuthProvider: mockAuth,
          child: const MyApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
