import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('AdminRepository Tests', () {
    late MockAdminService mockAdminService;
    late AdminRepository adminRepository;

    setUp(() {
      mockAdminService = MockAdminService();
      adminRepository = AdminRepository(mockAdminService);
    });

    test('getDepartments returns list on success', () async {
      final jsonResponse = jsonEncode({
        'success': true,
        'data': [
          {'id': 1, 'name': 'CSE'}
        ]
      });
      when(() => mockAdminService.get(any()))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await adminRepository.getDepartments();

      expect(result, isA<List<dynamic>>());
      expect(result.length, 1);
      expect(result.first['name'], 'CSE');
      verify(() => mockAdminService.get('/api/v1/admin/departments')).called(1);
    });

    test('getDepartments throws exception on failure', () async {
      when(() => mockAdminService.get(any()))
          .thenAnswer((_) async => http.Response('Error', 500));

      expect(() => adminRepository.getDepartments(), throwsException);
    });

    test('addDepartment posts data and returns response', () async {
      final jsonResponse = jsonEncode({
        'success': true,
        'data': {'id': 2, 'name': 'IT'}
      });
      when(() => mockAdminService.post(any(), any()))
          .thenAnswer((_) async => http.Response(jsonResponse, 201));

      final result = await adminRepository.addDepartment('IT', 'IT');

      expect(result['success'], true);
      expect(result['data']['name'], 'IT');
      verify(() => mockAdminService.post('/api/v1/admin/departments', {'name': 'IT', 'code': 'IT'})).called(1);
    });
  });
}
