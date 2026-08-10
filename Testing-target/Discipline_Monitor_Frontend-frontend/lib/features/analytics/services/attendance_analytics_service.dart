import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as api;
import 'package:pragatix/core/config/api_config.dart';

class AttendanceAnalyticsService {
  final String token;
  final String _baseUrl = '${ApiConfig.baseUrl}/api/v1/analytics/attendance';

  AttendanceAnalyticsService(this.token);

  String _buildQueryString(Map<String, dynamic> filters) {
    final queryParams = <String>[];
    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParams.add('$key=$value');
      }
    });
    return queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
  }

  String getExportUrl(Map<String, dynamic> filters) {
    final queryParams = <String>['access_token=$token'];
    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParams.add('$key=$value');
      }
    });
    return '$_baseUrl/export?${queryParams.join('&')}';
  }

  Future<Map<String, dynamic>> getOverview(Map<String, dynamic> filters) async {
    final response = await api.get(Uri.parse('$_baseUrl/overview${_buildQueryString(filters)}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<List<dynamic>> getTrend(Map<String, dynamic> filters) async {
    final response = await api.get(Uri.parse('$_baseUrl/trend${_buildQueryString(filters)}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getDistribution(Map<String, dynamic> filters) async {
    final response = await api.get(Uri.parse('$_baseUrl/distribution${_buildQueryString(filters)}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<List<dynamic>> getDepartmentWise(Map<String, dynamic> filters) async {
    final response = await api.get(Uri.parse('$_baseUrl/departments${_buildQueryString(filters)}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<List<dynamic>> getLowAttendanceStudents(Map<String, dynamic> filters, double threshold) async {
    final response = await api.get(Uri.parse('$_baseUrl/low-attendance${_buildQueryString({...filters, 'threshold': threshold})}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<List<dynamic>> getSectionWise(Map<String, dynamic> filters) async {
    final response = await api.get(Uri.parse('$_baseUrl/sections${_buildQueryString(filters)}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<List<dynamic>> getSummaryTable(Map<String, dynamic> filters) async {
    final response = await api.get(Uri.parse('$_baseUrl/summary-table${_buildQueryString(filters)}'), headers: {'Authorization': 'Bearer $token'});
    return json.decode(response.body);
  }

  Future<List<dynamic>> getDepartments() async {
    final response = await api.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'), headers: {'Authorization': 'Bearer $token'});
    final body = json.decode(response.body);
    return body['data'] ?? [];
  }

  Future<List<dynamic>> getSections(String departmentId) async {
    final response = await api.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections?departmentId=$departmentId'), headers: {'Authorization': 'Bearer $token'});
    final body = json.decode(response.body);
    return body['data'] ?? [];
  }
}
