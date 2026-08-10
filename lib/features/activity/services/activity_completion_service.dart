import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class ActivityCompletionService {
  final AuthProvider authProvider;

  ActivityCompletionService(this.authProvider);

  String get token => authProvider.token ?? '';

  Map<String, String> get _authHeaders => {'Authorization': 'Bearer $token'};

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> submitRequest(
    int activityId, {
    int? teamId,
    String? proofUrl,
    String? reason,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/activity-requests');
    final body = jsonEncode({
      'activityId': activityId,
      if (teamId != null) 'teamId': teamId,
      if (proofUrl != null && proofUrl.isNotEmpty) 'proofUrl': proofUrl,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });

    print('Complete URL: $url');
    print('HTTP Method: POST');
    print('Request Body: $body');

    final response = await http.post(url, headers: _jsonHeaders, body: body);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['success'] == false) {
        throw Exception(decoded['message'] ?? 'Failed to submit request');
      }
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } else {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      } catch (e) {
        if (e is! FormatException) rethrow;
      }
      throw Exception('Failed to submit request: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getMyRequests() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/activity-requests/my-requests',
    );

    print('Complete URL: $url');
    print('HTTP Method: GET');
    print('Request Body: (none)');

    final response = await http.get(url, headers: _authHeaders);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch requests: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getInbox({String? status}) async {
    final urlStr = status != null
        ? '${ApiConfig.baseUrl}/api/activity-requests/inbox?status=$status'
        : '${ApiConfig.baseUrl}/api/activity-requests/inbox';
    final url = Uri.parse(urlStr);

    print('Complete URL: $url');
    print('HTTP Method: GET');
    print('Request Body: (none)');

    final response = await http.get(url, headers: _authHeaders);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch inbox: ${response.body}');
    }
  }

  Future<int> getPendingCount() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/activity-requests/pending-count',
      );
      final response = await http.get(url, headers: _authHeaders);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        return json['data']?['pendingCount'] ?? 0;
      }
    } catch (e) {
      // Ignore
    }
    return 0;
  }

  Future<Map<String, dynamic>> approveRequest(int id) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/activity-requests/$id/approve',
    );

    print('Complete URL: $url');
    print('HTTP Method: PUT');
    print('Request Body: (none)');

    final response = await http.put(url, headers: _authHeaders);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to approve request: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> rejectRequest(int id, String reason) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/activity-requests/$id/reject',
    );
    final body = jsonEncode({'reason': reason});

    print('Complete URL: $url');
    print('HTTP Method: PUT');
    print('Request Body: $body');

    final response = await http.put(url, headers: _jsonHeaders, body: body);

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }
}
