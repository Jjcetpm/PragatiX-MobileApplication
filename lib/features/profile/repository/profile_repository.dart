import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/profile/models/profile_response.dart';

class ProfileRepository {
  Future<ProfileResponse> getMyProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/profile/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ProfileResponse.fromJson(data['data']);
        }
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }
}
