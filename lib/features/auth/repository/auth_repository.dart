import 'dart:convert';
import 'package:pragatix/features/auth/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<String> requestOtp(String email) async {
    final response = await _authService.requestOtp(email);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'OTP sent successfully';
    }
    throw Exception(data['message'] ?? 'Failed to send OTP.');
  }

  Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final response = await _authService.verifyOtp(email, otp);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    }
    throw Exception(data['message'] ?? 'OTP verification failed.');
  }
}
