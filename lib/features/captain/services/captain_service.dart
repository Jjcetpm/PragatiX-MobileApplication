import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;

class CaptainService {
  final AuthProvider authProvider;
  CaptainService(this.authProvider);

  String get token => authProvider.token ?? '';
  static const String baseUrl = ApiConfig.baseUrl;

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
