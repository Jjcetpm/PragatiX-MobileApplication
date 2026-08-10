import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class LeaderboardService {
  final AuthProvider authProvider;

  LeaderboardService(this.authProvider);

  String get token => authProvider.token ?? '';

  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? yearId,
    String? departmentId,
    String? sectionId,
  }) async {
    final Map<String, String> queryParams = {};
    if (yearId != null && yearId.isNotEmpty && yearId != 'All')
      queryParams['yearId'] = yearId;
    if (departmentId != null &&
        departmentId.isNotEmpty &&
        departmentId != 'All')
      queryParams['departmentId'] = departmentId;
    if (sectionId != null && sectionId.isNotEmpty && sectionId != 'All')
      queryParams['sectionId'] = sectionId;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/leaderboard',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    }
    throw Exception('Failed to load leaderboard');
  }

  Future<Map<String, dynamic>> getFilters({
    String? yearId,
    String? departmentId,
  }) async {
    final Map<String, String> queryParams = {};
    if (yearId != null && yearId.isNotEmpty && yearId != 'All')
      queryParams['yearId'] = yearId;
    if (departmentId != null &&
        departmentId.isNotEmpty &&
        departmentId != 'All')
      queryParams['departmentId'] = departmentId;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/leaderboard/filters',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data['success'] == true) {
        return Map<String, dynamic>.from(data['data'] ?? {});
      }
    }
    throw Exception('Failed to load leaderboard filters');
  }
}
