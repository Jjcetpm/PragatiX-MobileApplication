import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class AttendanceSettingsService {
  Future<Map<String, String>> _getHeaders() async {
    final token = getIt<AuthProvider>().token ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getSettings({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-settings';
    if (academicYear != null) {
      url += '?academicYear=$academicYear';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load attendance settings');
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data, {String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-settings';
    if (academicYear != null) {
      url += '?academicYear=$academicYear';
    }
    final response = await http.put(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to update attendance settings');
    }
  }

  Future<List<dynamic>> getAllHolidays({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-settings/holidays';
    if (academicYear != null) {
      url += '?academicYear=$academicYear';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load holidays');
    }
  }

  Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> data, {String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-settings/holidays';
    if (academicYear != null) {
      url += '?academicYear=$academicYear';
    }
    final response = await http.post(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to create holiday');
    }
  }

  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> data, {String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-settings/holidays/$id';
    if (academicYear != null) {
      url += '?academicYear=$academicYear';
    }
    final response = await http.put(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to update holiday');
    }
  }

  Future<void> deleteHoliday(int id, {String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-settings/holidays/$id';
    if (academicYear != null) {
      url += '?academicYear=$academicYear';
    }
    final response = await http.delete(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete holiday');
    }
  }

  // --- Engine Control Center ---

  Future<Map<String, dynamic>> getEngineStatus({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-engine/status';
    if (academicYear != null) url += '?academicYear=$academicYear';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to get engine status');
  }

  Future<Map<String, dynamic>> runDailyEngine({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-engine/run-daily';
    if (academicYear != null) url += '?academicYear=$academicYear';
    final response = await http.post(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to run daily engine: ${response.body}');
  }

  Future<Map<String, dynamic>> runWeeklyEngine({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-engine/run-weekly';
    if (academicYear != null) url += '?academicYear=$academicYear';
    final response = await http.post(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to run weekly engine: ${response.body}');
  }

  Future<Map<String, dynamic>> runBothEngines({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-engine/run-both';
    if (academicYear != null) url += '?academicYear=$academicYear';
    final response = await http.post(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to run both engines: ${response.body}');
  }

  Future<Map<String, dynamic>> resetEngineState({String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/attendance-engine/reset';
    if (academicYear != null) url += '?academicYear=$academicYear';
    final response = await http.post(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    }
    throw Exception('Failed to reset engine state: ${response.body}');
  }
}
