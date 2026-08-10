import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';

class AdminService {
  final AuthProvider authProvider;
  AdminService(this.authProvider);

  String get token => authProvider.token ?? '';

  Future<http.Response> get(String endpoint) async {
    return http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> post(String endpoint, Object body) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Object body) async {
    return http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
