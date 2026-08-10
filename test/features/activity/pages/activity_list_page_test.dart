import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/features/admin/pages/activity_tab.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_wrapper.dart';

void main() {
  group('AdminActivityManagementPage Widget Tests', () {
    late MockAdminRepository mockAdminRepo;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAdminRepo = MockAdminRepository();
      mockAuthProvider = MockAuthProvider();
      setupTestGetIt(adminRepo: mockAdminRepo);
    });

    testWidgets('renders loading state initially', (tester) async {
      when(() => mockAdminRepo.getStages()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });
      when(() => mockAdminRepo.getUsers()).thenAnswer((_) async => []);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const AdminActivityManagementPage(),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('renders stages when loaded', (tester) async {
      when(() => mockAdminRepo.getStages()).thenAnswer((_) async => [
            {
              'id': 1,
              'name': 'Test Stage',
              'description': 'Test Description',
              'startDate': '2026-01-01',
              'endDate': '2026-01-31',
              'isActive': true,
              'subgroups': []
            }
          ]);
      when(() => mockAdminRepo.getUsers()).thenAnswer((_) async => []);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const AdminActivityManagementPage(),
          ),
        );
        
        // Wait for Future to resolve
        await tester.pumpAndSettle();
        
        expect(find.text('Test Stage'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget); // FAB to add stage
      });
    });
  });
}
