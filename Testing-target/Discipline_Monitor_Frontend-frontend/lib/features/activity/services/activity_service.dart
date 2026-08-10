import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/activity/utils/constants.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – HTTP layer.
// Raw API calls only. No business logic. No model mapping.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityService {
  final AuthProvider authProvider;

  ActivityService(this.authProvider);

  String get token => authProvider.token ?? '';

  Map<String, String> get _authHeaders => {'Authorization': 'Bearer $token'};

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<dynamic>> fetchActivities({
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    String url = stageId != null
        ? '${ActivityConstants.baseUrl}/stages/$stageId/activities'
        : '${ActivityConstants.baseUrl}/activities';

    List<String> queryParams = [];
    if (subgroupName != null) queryParams.add('subgroup=$subgroupName');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }
    try {
      final response = await http.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as List?) ?? [];
        }
      } else if (response.statusCode == 404) {
        throw Exception('Stage not found.');
      } else if (response.statusCode == 500) {
        throw Exception('Unable to load activities.');
      }
      throw Exception(
        'Failed to fetch activities (status ${response.statusCode})',
      );
    } catch (e) {
      if (e is Exception && !e.toString().contains('SocketException')) {
        rethrow;
      }
      throw Exception('Internet Connection Error');
    }
  }

  Future<List<dynamic>> fetchGroupedActivities({
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    String url = '${ActivityConstants.baseUrl}/activities/grouped';

    List<String> queryParams = [];
    if (stageId != null) {
      queryParams.add('stageId=$stageId');
    }
    if (subgroupName != null && subgroupName.isNotEmpty) {
      queryParams.add('subgroup=$subgroupName');
    }
    if (academicYear != null && academicYear.isNotEmpty) {
      queryParams.add('academicYear=$academicYear');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }
    try {
      final response = await http.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as List?) ?? [];
        }
      }
      throw Exception(
        'Failed to fetch grouped activities (status ${response.statusCode})',
      );
    } catch (e) {
      if (e is Exception && !e.toString().contains('SocketException')) {
        rethrow;
      }
      throw Exception('Internet Connection Error');
    }
  }

  Future<List<dynamic>> fetchDepartments() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/departments'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception(
      'Failed to fetch departments (status ${response.statusCode})',
    );
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/users'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch users (status ${response.statusCode})');
  }

  Future<List<dynamic>> fetchClassCoordinators() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/departments/class-coordinators'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception(
      'Failed to fetch class coordinators (status ${response.statusCode})',
    );
  }

  Future<List<dynamic>> fetchCustomFrequencies() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/frequencies/custom'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception(
      'Failed to fetch custom frequencies (status ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> createCustomFrequency(
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('${ActivityConstants.baseUrl}/frequencies/custom'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to create custom frequency');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(
      data['message'] ??
          'Failed to create custom frequency (status ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ActivityConstants.baseUrl}/activities'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to create activity');
  }

  Future<Map<String, dynamic>> updateActivity(
    int activityId,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('${ActivityConstants.baseUrl}/activities/$activityId'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to update activity');
  }

  Future<void> mapActivityToStage(
    int stageId,
    int activityId,
    String subgroup,
  ) async {
    final response = await http.post(
      Uri.parse(
        '${ActivityConstants.baseUrl}/stages/$stageId/activities/$activityId?subgroup=$subgroup',
      ),
      headers: _authHeaders,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to map activity to stage');
    }
  }

  Future<void> unmapActivityFromStage(int stageId, int activityId) async {
    final response = await http.delete(
      Uri.parse(
        '${ActivityConstants.baseUrl}/stages/$stageId/activities/$activityId',
      ),
      headers: _authHeaders,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to unmap activity from stage');
    }
  }

  Future<void> deleteActivity(int activityId, {bool force = false}) async {
    String url =
        '${ActivityConstants.baseUrl}/activities/$activityId?force=$force';

    final response = await http.delete(Uri.parse(url), headers: _authHeaders);
    if (response.statusCode != 200) {
      String message = 'Failed to delete activity';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {}
      throw Exception(
        '${response.statusCode}:$message',
      ); // We pack status code to avoid importing ApiException if it causes cyclic imports or just throw a custom formatted exception
    }
  }

  Future<List<dynamic>> fetchSections() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/sections'),
      headers: _authHeaders,
    );
    debugPrint(
      'DEBUG_LOG: fetchSections API Response status: ${response.statusCode}',
    );
    debugPrint('DEBUG_LOG: fetchSections API Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch sections (status ${response.statusCode})');
  }

  Future<List<dynamic>> fetchAssignments(int activityId, [int? stageId]) async {
    final url = stageId != null
        ? '${ActivityConstants.baseUrl}/activities/$activityId/assignments?stageId=$stageId'
        : '${ActivityConstants.baseUrl}/activities/$activityId/assignments';
    final response = await http.get(
      Uri.parse(url),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch assignments');
  }

  Future<Map<String, dynamic>> addAssignment(
    int activityId,
    int departmentId,
    String year,
    int? sectionId,
    int? teacherId,
    String scope, [
    int? stageId,
  ]) async {
    final url = stageId != null
        ? '${ActivityConstants.baseUrl}/activities/$activityId/assignments?stageId=$stageId'
        : '${ActivityConstants.baseUrl}/activities/$activityId/assignments';
    final payload = {
      'stageId': stageId,
      'departmentId': departmentId,
      'year': year,
      'sectionId': sectionId,
      'teacherId': teacherId,
      'scope': scope,
    };
    
    print('========================');
    print('SAVE REQUEST');
    print('activityId=$activityId');
    print('stageId=$stageId');
    print('stageActivityMappingId=?');
    print('teacherId=$teacherId');
    print('departmentId=$departmentId');
    print('sectionId=$sectionId');
    print('assignmentType=$scope');
    print('assignmentMode=UNKNOWN'); // Need to fetch from somewhere, not in method args
    print('URL=$url');
    print('Payload=$payload');
    print('========================');

    final response = await http.post(
      Uri.parse(url),
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    print('SAVE RESPONSE BODY: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to add assignment');
  }

  Future<void> removeAssignment(int assignmentId) async {
    final response = await http.delete(
      Uri.parse(
        '${ActivityConstants.baseUrl}/activities/assignments/$assignmentId',
      ),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to remove assignment');
    }
  }

  Future<void> clearAllAssignments(int activityId, [int? stageId]) async {
    final url = stageId != null
        ? '${ActivityConstants.baseUrl}/activities/$activityId/assignments/clear?stageId=$stageId'
        : '${ActivityConstants.baseUrl}/activities/$activityId/assignments/clear';
    final response = await http.delete(
      Uri.parse(url),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to clear all assignments');
    }
  }

  Future<void> assignActivity(
    int activityId,
    bool ccEnabled,
    bool globalEnabled, [
    List<Map<String, dynamic>>? assignments,
    int? stageId,
  ]) async {
    final url = stageId != null
        ? '${ActivityConstants.baseUrl}/activities/$activityId/assign?stageId=$stageId'
        : '${ActivityConstants.baseUrl}/activities/$activityId/assign';
    final response = await http.post(
      Uri.parse(url),
      headers: _jsonHeaders,
      body: jsonEncode({
        'stageId': stageId,
        'ccEnabled': ccEnabled,
        'globalEnabled': globalEnabled,
        'assignments': assignments ?? [],
      }),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        data['message'] ?? 'Failed to update global assignment config',
      );
    }
  }

  Future<List<dynamic>> fetchMyActivities() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/my-activities'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception(
      'Failed to fetch my activities (status ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> fetchExecutionStudents(
    int activityId, {
    String? year,
    int? departmentId,
    int? sectionId,
    int? stageId,
  }) async {
    final rootUrl = ActivityConstants.baseUrl.replaceAll('/admin', '');

    // Build query parameters
    final Map<String, String> queryParams = {};
    if (year != null && year.isNotEmpty) queryParams['year'] = year;
    if (departmentId != null)
      queryParams['departmentId'] = departmentId.toString();
    if (sectionId != null) queryParams['sectionId'] = sectionId.toString();
    if (stageId != null) queryParams['stageId'] = stageId.toString();

    final uri = Uri.parse(
      '$rootUrl/my-activities/$activityId/students',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _authHeaders);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load execution students');
  }

  Future<void> awardXp({
    required int regNo,
    required int activityId,
    required int assignmentId,
    required int xp,
    required String remarks,
    String result = 'PASS',
  }) async {
    final rootUrl = ActivityConstants.baseUrl.replaceAll('/admin', '');
    final response = await http.post(
      Uri.parse('$rootUrl/student-xp/award'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'regNo': regNo,
        'activityId': activityId,
        'assignmentId': assignmentId,
        'xp': xp,
        'remarks': remarks,
        'result': result,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }
    throw Exception(data['message'] ?? 'Failed to award XP');
  }
}
