import 'dart:convert';
import 'package:pragatix/features/captain/services/captain_service.dart';

class CaptainRepository {
  final CaptainService _captainService;

  CaptainRepository(this._captainService);

  Future<List<Map<String, dynamic>>> getLeaderboardStudents() async {
    final response = await _captainService.getRawStudents(
      page: 0,
      size: 1000,
      sortBy: 'fullName',
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> content = data['data']['content'] ?? [];
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
    final response = await _captainService.getCurrentUser();
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final resData = data['data'];
      return {
        'id': resData['username'] ?? '24CS036',
        'name': resData['fullName'] ?? 'Sharugesh',
      };
    }
    return null;
  }
}
