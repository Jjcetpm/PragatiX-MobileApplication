import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class XpAnalyticsService {
  final String _baseUrl = '${ApiConfig.baseUrl}/api/v1/analytics/xp';
  
  Map<String, String> _getHeaders() {
    final token = getIt<AuthProvider>().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _buildQueryString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final queryParams = <String>[];
    params.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParams.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });
    return queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
  }

  Future<List<dynamic>> getDepartments() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'), headers: _getHeaders());
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'] ?? [];
    }
    throw Exception('Failed to load departments');
  }

  Future<List<dynamic>> getSections(String departmentId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments/$departmentId/sections'), headers: _getHeaders());
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'] ?? [];
    }
    throw Exception('Failed to load sections');
  }


  Future<List<dynamic>> getAwardVsPenalty(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/award-penalty${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load XP award vs penalty');
  }

  Future<List<dynamic>> getDepartmentRanking(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/departments${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load department ranking');
  }

  Future<List<dynamic>> getSectionRanking(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/sections${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load section ranking');
  }

  Future<List<dynamic>> getMonthlyHeatmap(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/heatmap${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load XP heatmap');
  }

  Future<List<dynamic>> getTopPerformers(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/top-performers${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load top performers');
  }

  Future<List<dynamic>> getLowXpStudents(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/low-xp${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load low XP students');
  }

  Future<List<dynamic>> getActivityXpContribution(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/activities${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load activity XP contribution');
  }

  Future<Map<String, dynamic>> getXpHistory(Map<String, dynamic> params) async {
    final response = await http.get(Uri.parse('$_baseUrl/history${_buildQueryString(params)}'), headers: _getHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load XP history');
  }

  String getExportUrl(Map<String, dynamic> params) {
    return '$_baseUrl/export-history${_buildQueryString(params)}';
  }
}
