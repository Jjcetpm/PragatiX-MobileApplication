import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

    testWidgets('renders login form correctly', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const LoginPage(),
          ),
        );

        // Verify title
        expect(find.text('SPDMS Login'), findsOneWidget);
        // Verify fields
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Sign In'), findsOneWidget);
        // Verify Dropdown
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      });
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const LoginPage(),
          ),
        );

        // Tap Sign In button
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Username, Email or Student ID is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        verifyNever(() => mockAuthRepo.studentLogin(any(), any()));
        verifyNever(() => mockAuthRepo.staffLogin(any(), any()));
      });
    });
  });
}
