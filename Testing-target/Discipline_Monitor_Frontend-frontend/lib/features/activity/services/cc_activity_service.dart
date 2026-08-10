import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class CCActivityService {
  final AuthProvider authProvider;

  CCActivityService(this.authProvider);

  String get token => authProvider.token ?? '';

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
  };

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static const String _baseEndpoint = '${ApiConfig.baseUrl}/api/v1/cc/activities';

  /// Fetch all active stages for CC, optionally filtered by academic year
  Future<List<Map<String, dynamic>>> fetchStages({String? academicYear}) async {
    try {
      String url = '$_baseEndpoint/stages';
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
        print('Error fetching CC stages: $e');
      }
      rethrow;
    }
  }

  /// Fetch active activities for CC, optionally filtered by stageId and subgroup
  Future<List<ActivityModel>> fetchActivities({int? stageId, String? subgroup}) async {
    try {
      final List<String> queryParams = [];
      if (stageId != null) queryParams.add('stageId=$stageId');
      if (subgroup != null && subgroup.isNotEmpty) queryParams.add('subgroup=$subgroup');

      String url = _baseEndpoint;
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
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
        print('Error fetching CC activities: $e');
      }
      rethrow;
    }
  }

  /// Fetch CC's assigned class details (Department, Year, Section)
  Future<Map<String, dynamic>> fetchClassDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseEndpoint/class-details'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as Map<String, dynamic>?) ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to load class details');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching CC class details: $e');
      }
      rethrow;
    }
  }

  /// Fetch students belonging to the CC's department and section
  Future<List<Map<String, dynamic>>> fetchClassStudents({int? activityId, int? stageId}) async {
    try {
      String url = '$_baseEndpoint/students';
      if (activityId != null) {
        url = '$_baseEndpoint/$activityId/students';
      }
      if (stageId != null) {
        url += '${url.contains('?') ? '&' : '?'}stageId=$stageId';
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
          throw Exception(data['message'] ?? 'Failed to load class students');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching CC class students: $e');
      }
      rethrow;
    }
  }

  /// Fetch teachers available to assign in the CC's class
  Future<List<Map<String, dynamic>>> fetchClassTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseEndpoint/teachers'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List rawList = (data['data'] as List?) ?? [];
          return rawList.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load teachers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching CC class teachers: $e');
      }
      rethrow;
    }
  }

  /// Assign activity to one selected teacher in CC's class
  /// [assignmentDuration] can be 'ONLY_TODAY' or 'PERMANENT'
  Future<Map<String, dynamic>> assignTeacherToActivity({
    required int activityId,
    required int teacherId,
    int? stageId,
    String? assignmentDuration,
    String? remarks,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseEndpoint/$activityId/assign-teacher'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'teacherId': teacherId,
          'stageId': stageId,
          'assignmentDuration': assignmentDuration ?? 'PERMANENT',
          'remarks': remarks,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data'] as Map<String, dynamic>?) ?? {};
      } else {
        throw Exception(data['message'] ?? 'Failed to assign teacher to activity');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error assigning teacher to activity: $e');
      }
      rethrow;
    }
  }

  /// Assign activity to selected students in CC's class
  Future<Map<String, dynamic>> assignActivity({
    required int activityId,
    List<int>? studentIds,
    String? remarks,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseEndpoint/$activityId/assign'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'studentIds': studentIds,
          'remarks': remarks,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data'] as Map<String, dynamic>?) ?? {};
      } else {
        throw Exception(data['message'] ?? 'Failed to assign activity');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error assigning activity: $e');
      }
      rethrow;
    }
  }
}
