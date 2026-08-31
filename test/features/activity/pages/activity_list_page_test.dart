import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
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
      when(() => mockAuthProvider.isAuthenticated).thenReturn(false);
      when(() => mockAuthProvider.currentUser).thenReturn(null);
      setupTestGetIt(adminRepo: mockAdminRepo);
    });

    testWidgets('renders loading state initially', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<List<dynamic>>();
      when(() => mockAdminRepo.getStages(academicYear: any(named: 'academicYear')))
          .thenAnswer((_) => completer.future);
      when(() => mockAdminRepo.getStages(academicYear: null))
          .thenAnswer((_) => completer.future);
      when(() => mockAdminRepo.getStages())
          .thenAnswer((_) => completer.future);
      when(() => mockAdminRepo.getUsers()).thenAnswer((_) async => []);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const AdminActivityManagementPage(),
          ),
        );
        expect(find.byType(PragatiXLoader), findsOneWidget);
        completer.complete([]);
        await tester.pump();
      });
    });

    testWidgets('renders stages when loaded', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockStages = [
        {
          'id': 1,
          'name': 'Test Stage',
          'description': 'Test Description',
          'startDate': '2026-01-01',
          'endDate': '2026-01-31',
          'isActive': true,
          'subgroups': []
        }
      ];
      when(() => mockAdminRepo.getStages(academicYear: any(named: 'academicYear')))
          .thenAnswer((_) async => mockStages);
      when(() => mockAdminRepo.getStages(academicYear: null))
          .thenAnswer((_) async => mockStages);
      when(() => mockAdminRepo.getStages())
          .thenAnswer((_) async => mockStages);
      when(() => mockAdminRepo.getUsers()).thenAnswer((_) async => []);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            mockAuthProvider: mockAuthProvider,
            child: const AdminActivityManagementPage(),
          ),
        );
        
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('Test Stage'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
      });
    });
  });
}
