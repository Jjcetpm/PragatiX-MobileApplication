import 'dart:convert';
import 'package:pragatix/features/auth/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<Map<String, dynamic>> staffLogin(
    String username,
    String password,
  ) async {
    final response = await _authService.staffLogin(username, password);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    }
    throw Exception(data['message'] ?? 'Staff login failed.');
  }

  Future<Map<String, dynamic>> studentLogin(
    String identity,
    String password,
  ) async {
    final response = await _authService.studentLogin(identity, password);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    }
    throw Exception(data['message'] ?? 'Student login failed.');
  }
}
