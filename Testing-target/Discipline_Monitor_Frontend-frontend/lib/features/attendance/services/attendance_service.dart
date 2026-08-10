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

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        List<dynamic> data = jsonResponse['data'];
        return data.map((e) => StudentAttendanceListItem.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load students');
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
      throw Exception('Failed to save attendance');
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

  Future<List<StudentAttendanceHistory>> getStudentHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/student/attendance/history'),
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
}
