import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/student/services/student_service.dart';

class StudentRepository {
  final StudentService _studentService;

  StudentRepository(this._studentService);

  Future<List<Map<String, dynamic>>> getLeaderboardStudents() async {
    final response = await http.get(
      Uri.parse('${StudentService.baseUrl}/api/v1/leaderboard'),
      headers: {'Authorization': 'Bearer ${_studentService.token}'},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> content = data['data'] ?? [];
      return content
          .map(
            (s) => {
              'regNo': s['regNo'] ?? '',
              'fullName': s['fullName'] ?? '',
              'departmentName': s['departmentName'] ?? '',
              'year': s['year'] ?? '',
              'section': s['section'] ?? '',
              'score': s['score'] ?? 0,
            },
          )
          .toList();
    }
    return [];
  }

  Future<Map<String, String>?> getCurrentUser() async {
    final response = await _studentService.getCurrentUser();
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final resData = data['data'];
      return {
        'id': (resData['username'] ?? resData['regNo'] ?? resData['sprNo'] ?? '').toString(),
        'name': (resData['fullName'] ?? 'Student').toString(),
      };
    }
    return null;
  }
}
