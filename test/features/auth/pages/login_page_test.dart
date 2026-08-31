import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_wrapper.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late MockAuthRepository mockAuthRepo;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockAuthProvider = MockAuthProvider();
      setupTestGetIt(authRepo: mockAuthRepo);
    });

    testWidgets('renders login form with graduate theme correctly', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const LoginPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify title & subtitle
        expect(find.text('Enter your email to receive an OTP'), findsOneWidget);

        // Verify Email input field
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Send OTP'), findsOneWidget);

        // Verify Policy checkbox
        expect(find.byType(Checkbox), findsOneWidget);
      });
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const LoginPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Check the policy box first
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Tap Send OTP
        await tester.tap(find.text('Send OTP'));
        await tester.pumpAndSettle();

        // Verify validation error
        expect(find.text('Email is required'), findsOneWidget);
      });
    });
  });
}