import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';

class AuthService {
  Future<http.Response> staffLogin(String username, String password) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
  }

  Future<http.Response> studentLogin(String identity, String password) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/student-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identity': identity, 'password': password}),
    );
  }
}
