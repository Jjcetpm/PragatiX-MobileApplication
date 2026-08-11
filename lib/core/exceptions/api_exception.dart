import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Called whenever a 401 is received — clears session and redirects to login.
void _handleSessionExpired() {
  // Clear stored auth state
  final auth = getIt<AuthProvider>();
  auth.logout();

  // Navigate to login, removing all previous routes
  final nav = NavigatorService.navigatorKey.currentState;
  if (nav != null) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

Future<http.Response> processResponse(http.Response response) async {
  if (response.statusCode == 401) {
    // Token expired — auto-logout
    _handleSessionExpired();
    throw ApiException(401, 'Session expired. Please login again.');
  }

  if (response.statusCode >= 400 || (response.body.isNotEmpty && response.body.trim().startsWith('<'))) {
    String message = 'An error occurred';
    try {
      if (response.body.trim().startsWith('<')) {
        message = 'Server returned an HTML page (Possible Backend Error or Gateway Timeout)';
      } else {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['error'] ?? message;
      }
    } catch (_) {}
    // If it was a 200 OK with HTML, we treat it as a 500 server error logically.
    final statusCode = response.statusCode < 400 ? 500 : response.statusCode;
    throw ApiException(statusCode, message);
  }
  return response;
}

