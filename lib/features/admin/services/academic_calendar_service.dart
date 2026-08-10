import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class AcademicCalendarService {
  Future<Map<String, String>> _getHeaders() async {
    final token = getIt<AuthProvider>().token ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // --- Month ---
  Future<Map<String, dynamic>> getOrCreateMonth(int month, int year, {String? academicYear}) async {
    String url = '${ApiConfig.baseUrl}/api/v1/academic-calendar/month?month=$month&year=$year';
    if (academicYear != null) {
      url += '&academicYear=$academicYear';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load academic month');
    }
  }

  // --- Weeks ---
  Future<List<dynamic>> getWeeks(int monthId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/month/$monthId/weeks'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load weeks');
    }
  }

  Future<Map<String, dynamic>> addWeek(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/weeks'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to add week');
    }
  }

  Future<Map<String, dynamic>> updateWeek(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/weeks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update week');
    }
  }

  Future<void> deleteWeek(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/weeks/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete week');
    }
  }

  // --- Holidays ---
  Future<List<dynamic>> getHolidays(int monthId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/month/$monthId/holidays'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load holidays');
    }
  }

  Future<Map<String, dynamic>> addHoliday(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/holidays'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to add holiday');
    }
  }

  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/holidays/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update holiday');
    }
  }

  Future<void> deleteHoliday(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/holidays/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete holiday');
    }
  }

  // --- Alternate Working Days ---
  Future<List<dynamic>> getAlternateWorkingDays(int monthId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/month/$monthId/alternate-working-days'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load alternate working days');
    }
  }

  Future<Map<String, dynamic>> addAlternateWorkingDay(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/alternate-working-days'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to add alternate working day');
    }
  }

  Future<Map<String, dynamic>> updateAlternateWorkingDay(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/alternate-working-days/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update alternate working day');
    }
  }

  Future<void> deleteAlternateWorkingDay(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/academic-calendar/alternate-working-days/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete alternate working day');
    }
  }
}
