import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pinput/pinput.dart';
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

    testWidgets('transitions to OTP step and configures Pinput with AutofillHints.oneTimeCode and null smsRetriever', (tester) async {
      when(() => mockAuthRepo.requestOtp(any()))
          .thenAnswer((_) async => 'OTP sent successfully');

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const LoginPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Enter valid email
        await tester.enterText(find.byType(TextFormField), 'student@college.edu');
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Tap Send OTP
        await tester.tap(find.text('Send OTP'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify OTP step is displayed
        expect(find.text('Enter the 4-digit OTP sent to your email'), findsOneWidget);

        // Verify Pinput exists with correct autofill hints, keyboard, length, and no SMS retriever
        final pinputFinder = find.byType(Pinput);
        expect(pinputFinder, findsOneWidget);

        final pinputWidget = tester.widget<Pinput>(pinputFinder);
        expect(pinputWidget.autofillHints, contains(AutofillHints.oneTimeCode));
        expect(pinputWidget.smsRetriever, isNull);
        expect(pinputWidget.keyboardType, TextInputType.number);
        expect(pinputWidget.length, 4);
        expect(pinputWidget.autofocus, isTrue);
      });
    });

    testWidgets('entering complete 4-digit OTP triggers auto-verification', (tester) async {
      when(() => mockAuthRepo.requestOtp(any()))
          .thenAnswer((_) async => 'OTP sent successfully');
      when(() => mockAuthRepo.verifyOtp(any(), '1234'))
          .thenThrow(Exception('Invalid OTP'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const LoginPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Enter email and request OTP
        await tester.enterText(find.byType(TextFormField), 'admin@college.edu');
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send OTP'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Enter complete 4-digit OTP
        final pinputFinder = find.byType(Pinput);
        expect(pinputFinder, findsOneWidget);

        await tester.enterText(pinputFinder, '1234');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify verifyOtp was called with the entered OTP
        verify(() => mockAuthRepo.verifyOtp('admin@college.edu', '1234')).called(1);
      });
    });
  });
}