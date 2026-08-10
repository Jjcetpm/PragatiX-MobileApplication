import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  Map<String, dynamic>? _currentUser;
  String? _selectedAcademicYear;

  // Getters
  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get selectedAcademicYear => _selectedAcademicYear;
  bool get isAuthenticated => _token != null;

  bool get isSuperAdmin {
    final roles = _currentUser?['roles'] as List<dynamic>?;
    if (roles == null) return false;
    for (var r in roles) {
      String roleName = '';
      if (r is String) roleName = r;
      if (r is Map) roleName = r['name']?.toString() ?? '';
      if (roleName == 'ROLE_SUPER_ADMIN' || roleName == 'ROLE_SUPERADMIN') return true;
    }
    return false;
  }

  // Setters
  Future<void> login(
    String token,
    String role,
    Map<String, dynamic> user,
  ) async {
    _token = token;
    _role = role;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', role);
    await prefs.setString('auth_user', jsonEncode(user));
    notifyListeners();
  }

  Future<void> setSelectedAcademicYear(String? year) async {
    _selectedAcademicYear = year;
    final prefs = await SharedPreferences.getInstance();
    if (year != null) {
      await prefs.setString('auth_academic_year', year);
    } else {
      await prefs.remove('auth_academic_year');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _currentUser = null;
    _selectedAcademicYear = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');

    if (savedToken == null || savedToken.isEmpty) {
      await logout();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('\${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer $savedToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _token = savedToken;
          _role = prefs.getString('auth_role');
          _selectedAcademicYear = prefs.getString('auth_academic_year');
          _currentUser = data['data'];

          // Update cached user with fresh data
          await prefs.setString('auth_user', jsonEncode(_currentUser));
          notifyListeners();
          return;
        }
      }

      // If we get here, token is invalid or request failed
      await logout();
    } catch (e) {
      // Network error or parsing error
      await logout();
    }
  }

  // Placeholder for token refresh
  Future<void> refreshToken() async {
    // TODO: Implement token refresh logic
  }
}
