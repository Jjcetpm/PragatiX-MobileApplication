import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pragatix/core/utils/api_client.dart' as standard_http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/admin/services/admin_service.dart';
import 'package:pragatix/features/enrollment/models/enrollment_model.dart';

class EnrollmentRepository {
  final AdminService _adminService;

  EnrollmentRepository(this._adminService);

  // ==========================================
  // PUBLIC ENROLLMENT FLOW (NO AUTH TOKEN)
  // ==========================================

  Future<bool> getPublicStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/public/enrollment/status');
      final response = await standard_http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['enabled'] == true;
        }
      }
    } catch (e) {
      debugPrint('Error checking public enrollment status: $e');
    }
    return false;
  }

  Future<List<PendingDepartment>> getPendingDepartments() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/public/enrollment/departments');
    final response = await standard_http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => PendingDepartment.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load pending departments');
  }

  Future<List<String>> getPendingAlphabets(int departmentId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/public/enrollment/alphabets?departmentId=$departmentId');
    final response = await standard_http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => e.toString()).toList();
      }
    }
    throw Exception('Failed to load pending alphabets');
  }

  Future<List<PendingStudent>> getPendingStudents(int departmentId, String letter) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/public/enrollment/students?departmentId=$departmentId&letter=$letter');
    final response = await standard_http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => PendingStudent.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load pending students');
  }

  Future<Map<String, dynamic>> completeEnrollment(int enrollmentId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/public/enrollment/complete');
    final response = await standard_http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'enrollmentId': enrollmentId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? data['error'] ?? 'Enrollment failed');
  }

  // ==========================================
  // ADMIN ENROLLMENT MANAGEMENT (WITH AUTH TOKEN)
  // ==========================================

  Future<bool> getAdminStatus() async {
    final response = await _adminService.get('/api/v1/admin/enrollment/status');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data']['enabled'] == true;
      }
    }
    return false;
  }

  Future<void> updateStatus(bool enabled) async {
    final response = await _adminService.put('/api/v1/admin/enrollment/status', {
      'enabled': enabled,
    });
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update enrollment status');
    }
  }

  Future<List<PendingDepartment>> getEnrollmentDepartments() async {
    final response = await _adminService.get('/api/v1/admin/enrollment/departments');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => PendingDepartment.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load enrollment departments');
  }

  Future<List<int>> downloadTemplate() async {
    final response = await _adminService.get('/api/v1/admin/enrollment/template');
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download template');
  }

  Future<EnrollmentImportResult> importExcel(List<int> fileBytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/enrollment/import');
    final request = standard_http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_adminService.token}';
    request.files.add(
      standard_http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await standard_http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return EnrollmentImportResult.fromJson(data['data'] ?? {});
    }
    throw Exception(data['message'] ?? data['error'] ?? 'Import failed');
  }

  Future<EnrollmentItem> addSingleEnrollment({
    required String fullName,
    required String gender,
    required String email,
    required String mobile,
    required int departmentId,
    String? section,
    int? sectionId,
  }) async {
    final Map<String, dynamic> body = {
      'fullName': fullName.trim(),
      'gender': gender,
      'email': email.trim().toLowerCase(),
      'mobile': mobile.trim(),
      'departmentId': departmentId,
    };
    if (section != null && section.trim().isNotEmpty) {
      body['section'] = section.trim();
    }
    if (sectionId != null) {
      body['sectionId'] = sectionId;
    }
    final response = await _adminService.post('/api/v1/admin/enrollment/single', body);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return EnrollmentItem.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? data['error'] ?? 'Failed to add student');
  }

  Future<EnrollmentItem> updateEnrollment(
    int id, {
    required String fullName,
    required String gender,
    required String email,
    required String mobile,
    required int departmentId,
    String? section,
    int? sectionId,
  }) async {
    final Map<String, dynamic> body = {
      'fullName': fullName.trim(),
      'gender': gender,
      'email': email.trim().toLowerCase(),
      'mobile': mobile.trim(),
      'departmentId': departmentId,
    };
    if (section != null && section.trim().isNotEmpty) {
      body['section'] = section.trim();
    } else {
      body['section'] = null;
    }
    if (sectionId != null) {
      body['sectionId'] = sectionId;
    } else {
      body['sectionId'] = null;
    }
    final response = await _adminService.put('/api/v1/admin/enrollment/$id', body);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return EnrollmentItem.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? data['error'] ?? 'Failed to update student');
  }

  Future<void> deleteEnrollment(int id) async {
    final response = await _adminService.delete('/api/v1/admin/enrollment/$id');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to delete student');
    }
  }

  Future<Map<String, dynamic>> getPendingList({
    int page = 0,
    int size = 20,
    String? search,
    int? departmentId,
  }) async {
    String endpoint = '/api/v1/admin/enrollment/pending?page=$page&size=$size';
    if (search != null && search.trim().isNotEmpty) {
      endpoint += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (departmentId != null) {
      endpoint += '&departmentId=$departmentId';
    }

    final response = await _adminService.get(endpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final pageData = data['data'];
        final List<dynamic> content = pageData['content'] ?? [];
        return {
          'items': content.map((e) => EnrollmentItem.fromJson(e)).toList(),
          'totalElements': pageData['totalElements'] ?? 0,
          'totalPages': pageData['totalPages'] ?? 1,
          'last': pageData['last'] ?? true,
        };
      }
    }
    throw Exception('Failed to load pending enrollments');
  }

  Future<Map<String, dynamic>> getEnrolledList({
    int page = 0,
    int size = 20,
    String? search,
    int? departmentId,
  }) async {
    String endpoint = '/api/v1/admin/enrollment/enrolled?page=$page&size=$size';
    if (search != null && search.trim().isNotEmpty) {
      endpoint += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (departmentId != null) {
      endpoint += '&departmentId=$departmentId';
    }

    final response = await _adminService.get(endpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final pageData = data['data'];
        final List<dynamic> content = pageData['content'] ?? [];
        return {
          'items': content.map((e) => EnrollmentItem.fromJson(e)).toList(),
          'totalElements': pageData['totalElements'] ?? 0,
          'totalPages': pageData['totalPages'] ?? 1,
          'last': pageData['last'] ?? true,
        };
      }
    }
    throw Exception('Failed to load enrolled students');
  }
}
