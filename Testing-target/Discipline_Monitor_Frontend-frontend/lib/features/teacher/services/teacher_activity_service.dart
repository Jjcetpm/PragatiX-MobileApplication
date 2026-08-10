import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class TeacherActivityService {
  final AuthProvider authProvider;

  TeacherActivityService(this.authProvider);

  String get token => authProvider.token ?? '';

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
  };

  /// Fetch all active stages with thresholds for Teacher
  Future<List<Map<String, dynamic>>> fetchStages({String? academicYear}) async {
    try {
      String url = '${ApiConfig.baseUrl}/api/v1/admin/stages';
      if (academicYear != null && academicYear.isNotEmpty) {
        url += '?academicYear=${Uri.encodeComponent(academicYear)}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List rawList = (data['data'] as List?) ?? [];
          return rawList.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load stages');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching teacher stages: $e');
      }
      rethrow;
    }
  }

  /// Fetch active activities for a specific stage and subgroup
  Future<List<ActivityModel>> fetchActivities({
    required int stageId,
    String? subgroup,
    String? academicYear,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (subgroup != null && subgroup.isNotEmpty) {
        queryParams['subgroup'] = subgroup;
      }
      if (academicYear != null && academicYear.isNotEmpty) {
        queryParams['academicYear'] = academicYear;
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages/$stageId/activities')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List rawList = (data['data'] as List?) ?? [];
          return rawList
              .map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load activities');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching teacher activities: $e');
      }
      rethrow;
    }
  }
}
