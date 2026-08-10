import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/config/api_config.dart';

class HodAnalyticsService {
  Future<Map<String, dynamic>> getHodDashboard({
    String? year,
    required String token,
  }) async {
    String url = '${ApiConfig.baseUrl}/api/v1/hod/analytics/dashboard';
    if (year != null && year.isNotEmpty && year != 'All Years') {
      url += '?year=${Uri.encodeComponent(year)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true && decoded['data'] != null) {
        return decoded['data'] as Map<String, dynamic>;
      }
      throw Exception(decoded['message'] ?? 'Failed to load HOD analytics data');
    } else {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['message'] ?? 'HTTP ${response.statusCode}: Failed to fetch HOD analytics');
    }
  }
}
