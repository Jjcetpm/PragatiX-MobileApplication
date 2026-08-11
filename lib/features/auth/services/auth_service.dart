import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';

class AuthService {
  Future<http.Response> requestOtp(String email) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

  Future<http.Response> verifyOtp(String email, String otp) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
  }
}
