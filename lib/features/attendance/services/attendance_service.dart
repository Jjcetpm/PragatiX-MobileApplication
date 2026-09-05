import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import '../models/student_attendance_summary.dart';
import '../models/student_attendance_history.dart';
import '../models/student_attendance_list_item.dart';
import '../models/admin_attendance_summary.dart';

class AttendanceService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = getIt<AuthProvider>().token ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Teacher Endpoints
  Future<List<StudentAttendanceListItem>> getStudentsWithAttendance(
    String date,
    int period,
    int yearId,
    int departmentId, {
    int? sectionId,
  }) async {
    String url =
        '$_baseUrl/api/teacher/attendance/students?date=$date&period=$period&yearId=$yearId&departmentId=$departmentId';
    if (sectionId != null) {
      url += '&sectionId=$sectionId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    try {
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        List<dynamic> data = jsonResponse['data'];
        return data.map((e) => StudentAttendanceListItem.fromJson(e)).toList();
      }
      throw Exception(jsonResponse['message'] ?? 'Failed to load students');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to load students');
    }
  }

  Future<void> saveAttendance(
    String date,
    int period,
    int academicYearId,
    int yearId,
    int departmentId,
    int? sectionId,
    List<StudentAttendanceListItem> records,
  ) async {
    final payload = {
      'date': date,
      'period': period,
      'academicYearId': academicYearId,
      'yearId': yearId,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'records': records.map((r) => r.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/teacher/attendance/save'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      try {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Failed to save attendance');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to save attendance');
      }
    }
  }

  // Admin Endpoints
  Future<AdminAttendanceSummary> getAdminSummary(
    String date,
    int yearId,
    int? departmentId, {
    int? sectionId,
    int? period,
  }) async {
    String url =
        '$_baseUrl/api/admin/attendance/summary?date=$date&yearId=$yearId';
    if (departmentId != null) {
      url += '&departmentId=$departmentId';
    }
    if (sectionId != null) {
      url += '&sectionId=$sectionId';
    }
    if (period != null) {
      url += '&period=$period';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        return AdminAttendanceSummary.fromJson(jsonResponse['data']);
      }
    }
    throw Exception('Failed to load admin summary');
  }

  Future<List<Map<String, dynamic>>> getAdminAttendanceHistory({
    String? date,
    int? yearId,
    int? departmentId,
    int? sectionId,
    int? period,
  }) async {
    final params = <String>[];
    if (date != null) params.add('date=$date');
    if (yearId != null) params.add('yearId=$yearId');
    if (departmentId != null) params.add('departmentId=$departmentId');
    if (sectionId != null) params.add('sectionId=$sectionId');
    if (period != null) params.add('period=$period');

    String url = '$_baseUrl/api/admin/attendance/history';
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is Map && jsonResponse['data'] != null && jsonResponse['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      }
      if (jsonResponse is List) {
        return List<Map<String, dynamic>>.from(jsonResponse);
      }
      return [];
    }
    throw Exception('Failed to load attendance history');
  }

  // Student Endpoints
  Future<StudentAttendanceSummary> getStudentSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/student/attendance/summary'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        return StudentAttendanceSummary.fromJson(jsonResponse['data']);
      }
    }
    throw Exception('Failed to load student summary');
  }

  Future<List<StudentAttendanceHistory>> getStudentHistory({String? date}) async {
    String url = '$_baseUrl/api/student/attendance/history';
    if (date != null) {
      url += '?date=$date';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        List<dynamic> data = jsonResponse['data'];
        return data.map((e) => StudentAttendanceHistory.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load student history');
  }

  Future<int> getNextAvailablePeriod(
    String date,
    int departmentId, {
    int? yearId,
    int? sectionId,
  }) async {
    String url =
        '$_baseUrl/api/teacher/attendance/next-period?date=$date&departmentId=$departmentId';
    if (yearId != null) {
      url += '&yearId=$yearId';
    }
    if (sectionId != null) {
      url += '&sectionId=$sectionId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        return jsonResponse['data'] as int;
      }
    }
    return 1; // Default to period 1 if error
  }

  Future<List<Map<String, dynamic>>> getMarkedPeriods(
    String date,
    int departmentId, {
    int? yearId,
    int? sectionId,
  }) async {
    String url =
        '$_baseUrl/api/teacher/attendance/marked-periods?date=$date&departmentId=$departmentId';
    if (yearId != null) {
      url += '&yearId=$yearId';
    }
    if (sectionId != null) {
      url += '&sectionId=$sectionId';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          final list = jsonResponse['data'] as List<dynamic>? ?? [];
          return list.map((e) {
            if (e is Map<String, dynamic>) return e;
            if (e is Map) return Map<String, dynamic>.from(e);
            if (e is num) return {'period': e.toInt(), 'canViewHistory': true, 'isMarkedByMe': true};
            return <String, dynamic>{};
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
