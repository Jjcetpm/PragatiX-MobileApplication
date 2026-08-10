import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/team/models/team.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class GroupActivityService {
  final AuthProvider authProvider;

  GroupActivityService(this.authProvider);

  String get token => authProvider.token ?? '';

  Future<List<Team>> getTeamsForAssignment(int assignmentId, {int? stageId}) async {
    final uri = stageId != null
        ? Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/group-activities/assignments/$assignmentId/teams?stageId=$stageId',
          )
        : Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/group-activities/assignments/$assignmentId/teams',
          );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((team) => Team.fromJson(team)).toList();
      } else {
        throw Exception(jsonResponse['message']);
      }
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<void> awardXpToTeam({
    required int teamId,
    required int assignmentId,
    required bool equalDistribution,
    required int xp,
    String? remarks,
    List<Map<String, dynamic>>? studentsData,
  }) async {
    final Map<String, dynamic> body = {
      'assignmentId': assignmentId,
      'equalDistribution': equalDistribution,
      if (equalDistribution) 'xp': xp,
      if (equalDistribution && remarks != null) 'remarks': remarks,
      if (!equalDistribution && studentsData != null) 'students': studentsData,
    };

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/group-activities/teams/$teamId/award-xp',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (!jsonResponse['success']) {
        throw Exception(jsonResponse['message']);
      }
    } else {
      throw Exception('Failed to award XP to team');
    }
  }

  Future<void> deleteTeam(int teamId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/$teamId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (!jsonResponse['success']) {
        throw Exception(jsonResponse['message']);
      }
    } else if (response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 409) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message']);
    } else {
      throw Exception('Failed to delete team');
    }
  }

  Future<http.Response> searchStudents(
    String keyword,
    int page,
    int size,
  ) async {
    return http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/students/search?keyword=${Uri.encodeComponent(keyword)}&page=$page&size=$size',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> createTeam(Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}
