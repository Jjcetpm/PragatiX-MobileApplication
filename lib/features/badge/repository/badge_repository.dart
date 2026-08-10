import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:flutter/foundation.dart';

class BadgeRepository {
  Future<Map<String, dynamic>> fetchMyBadges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/student/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load badges',
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAllBadges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load badges',
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitBadgeClaim(
    String token,
    String badgeName,
    String evidenceUrl,
  ) async {
    try {
      debugPrint(
        'BadgeRepository: POST URL: ${ApiConfig.baseUrl}/api/v1/badges/submit',
      );
      final bodyStr = jsonEncode({
        'badgeName': badgeName,
        'evidenceUrl': evidenceUrl,
      });
      debugPrint('BadgeRepository: Request Body: $bodyStr');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: bodyStr,
      );

      debugPrint('BadgeRepository: Response Code: ${response.statusCode}');
      debugPrint('BadgeRepository: Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Badge claim submitted successfully!',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to claim badge',
      };
    } catch (e) {
      debugPrint('BadgeRepository: JSON Parsing/Network error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchTeacherPendingClaims(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch claims',
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> approveClaim(String token, int claimId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/$claimId/approve'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Badge claim approved successfully!',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to approve claim',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectClaim(String token, int claimId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/$claimId/reject'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Badge claim rejected successfully!',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to reject claim',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- NEW BADGE REQUEST API (Workflow) ---

  Future<Map<String, dynamic>> requestBadge(
    String token,
    int badgeId,
    String proofLink,
  ) async {
    try {
      final bodyStr = jsonEncode({'badgeId': badgeId, 'proofLink': proofLink});
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/badge-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: bodyStr,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Badge requested successfully',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to request badge',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/badge-requests/my'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load requests',
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAdminRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/badge-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load requests',
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCCRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/cc/badge-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load requests',
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> approveWorkflowRequest(
    String token,
    int requestId,
    String role,
  ) async {
    try {
      String endpoint = role == 'ADMIN' ? 'admin' : 'cc';
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/$endpoint/badge-requests/$requestId/approve',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Request approved'};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to approve request',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectWorkflowRequest(
    String token,
    int requestId,
    String role, {
    String? remarks,
  }) async {
    try {
      String endpoint = role == 'ADMIN' ? 'admin' : 'cc';
      final bodyStr = remarks != null ? jsonEncode({'remarks': remarks}) : null;
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/$endpoint/badge-requests/$requestId/reject',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          if (bodyStr != null) 'Content-Type': 'application/json',
        },
        body: bodyStr,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Request rejected'};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to reject request',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
