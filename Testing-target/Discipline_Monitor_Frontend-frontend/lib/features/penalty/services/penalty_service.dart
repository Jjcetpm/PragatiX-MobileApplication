import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/penalty/models/penalty_request.dart';

class PenaltyService {
  final AuthProvider authProvider;
  PenaltyService(this.authProvider);

  String get token => authProvider.token ?? '';
  static const String baseUrl = ApiConfig.baseUrl;

  Future<int> getPendingCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/penalties/pending-count'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']?['pendingCount'] ?? 0;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }

  Future<List<PenaltyRequest>> getCcInbox() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/penalties/cc-inbox'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => PenaltyRequest.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch CC inbox');
  }

  Future<List<PenaltyRequest>> getMyRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/penalties/my-requests'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => PenaltyRequest.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch my requests');
  }

  Future<PenaltyRequest> submitPenalty({
    required String regNo,
    int? activityId,
    String? activityName,
    required int penaltyXP,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/penalties'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'regNo': regNo,
        'activityId': activityId,
        'activityName': activityName,
        'penaltyXP': penaltyXP,
        'reason': reason,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return PenaltyRequest.fromJson(json['data']);
    }
    throw Exception('Failed to submit penalty');
  }

  Future<PenaltyRequest> approvePenalty(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/penalties/$id/approve'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PenaltyRequest.fromJson(json['data']);
    }
    throw Exception('Failed to approve penalty');
  }

  Future<PenaltyRequest> rejectPenalty(int id, String reason) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/penalties/$id/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PenaltyRequest.fromJson(json['data']);
    }
    throw Exception('Failed to reject penalty');
  }
}
