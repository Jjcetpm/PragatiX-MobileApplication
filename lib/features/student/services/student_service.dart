import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/student/models/student.dart';

class StudentService {
  final AuthProvider authProvider;
  StudentService(this.authProvider);

  String get token => authProvider.token ?? '';
  static const String baseUrl = ApiConfig.baseUrl;

  Future<List<Student>> getStudents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/students'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => Student.fromJson(e)).toList();
    }
    return [];
  }

  Future<http.Response> getRawStudents({
    int page = 0,
    int size = 1000,
    String sortBy = 'fullName',
  }) async {
    return http.get(
      Uri.parse(
        '$baseUrl/api/v1/students?page=$page&size=$size&sortBy=$sortBy',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> getCurrentUser() async {
    return http.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
