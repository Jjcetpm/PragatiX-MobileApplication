import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/scanner/models/scanned_student_models.dart';

class StudentScannerService {
  final String token;
  static const String baseUrl = ApiConfig.baseUrl;

  StudentScannerService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Lookup student by scanned payload or manual SPR / register number
  Future<ScannedStudentProfileModel> lookupStudent(String identifier) async {
    final uri = Uri.parse('$baseUrl/api/v1/scanner/student?identifier=${Uri.encodeComponent(identifier.trim())}');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as Map<String, dynamic>;
      return ScannedStudentProfileModel.fromJson(data);
    } else {
      String msg = 'No student found for this SPR number.';
      try {
        final err = jsonDecode(response.body);
        if (err['message'] != null) {
          msg = err['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Get eligible activities authorized for authenticated staff and scanned student
  Future<List<EligibleActivityModel>> getEligibleActivities(int studentId) async {
    final uri = Uri.parse('$baseUrl/api/v1/scanner/student/$studentId/activities');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => EligibleActivityModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      String msg = 'Failed to fetch eligible activities.';
      try {
        final err = jsonDecode(response.body);
        if (err['message'] != null) {
          msg = err['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Award XP to scanned student
  Future<ScannerTransactionResultModel> awardXp(ScannerAwardModel request) async {
    final uri = Uri.parse('$baseUrl/api/v1/scanner/award');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as Map<String, dynamic>;
      return ScannerTransactionResultModel.fromJson(data);
    } else {
      String msg = 'Failed to award XP.';
      try {
        final err = jsonDecode(response.body);
        if (err['message'] != null) {
          msg = err['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Apply penalty XP to scanned student
  Future<ScannerTransactionResultModel> applyPenalty(ScannerPenaltyModel request) async {
    final uri = Uri.parse('$baseUrl/api/v1/scanner/penalty');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as Map<String, dynamic>;
      return ScannerTransactionResultModel.fromJson(data);
    } else {
      String msg = 'Failed to apply penalty.';
      try {
        final err = jsonDecode(response.body);
        if (err['message'] != null) {
          msg = err['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}

