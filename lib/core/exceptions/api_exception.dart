import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/core/services/server_status_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'Please check your internet connection and try again.']);

  @override
  String toString() => message;
}

class ServerMaintenanceException implements Exception {
  final String message;
  ServerMaintenanceException([this.message = 'Please try again later.']);

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
    // Check if the request is an auth endpoint (like verify-otp), in which case it's not a session expiry
    final path = response.request?.url.path ?? '';
    if (!path.contains('/auth/')) {
      // Token expired — auto-logout
      _handleSessionExpired();
      throw ApiException(401, 'Session expired. Please login again.');
    }
  }

  // Handle server down / maintenance HTTP status codes (500, 502, 503, 504)
  if (response.statusCode >= 500) {
    ServerStatusService.instance.setMaintenanceMode(true);
    throw ServerMaintenanceException('Please try again later.');
  }

  if (response.statusCode >= 400 || (response.body.isNotEmpty && response.body.trim().startsWith('<'))) {
    String message = 'An error occurred';
    try {
      if (response.body.trim().startsWith('<')) {
        // Backend offline / gateway error returned HTML
        ServerStatusService.instance.setMaintenanceMode(true);
        throw ServerMaintenanceException('Please try again later.');
      } else {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['error'] ?? message;
      }
    } on ServerMaintenanceException {
      rethrow;
    } catch (_) {}

    final lowerMsg = message.toLowerCase();
    if (lowerMsg.contains('maintenance') ||
        lowerMsg.contains('service unavailable') ||
        lowerMsg.contains('bad gateway')) {
      ServerStatusService.instance.setMaintenanceMode(true);
      throw ServerMaintenanceException('Please try again later.');
    }

    final statusCode = response.statusCode < 400 ? 500 : response.statusCode;
    if (statusCode >= 500) {
      ServerStatusService.instance.setMaintenanceMode(true);
      throw ServerMaintenanceException('Please try again later.');
    }
    throw ApiException(statusCode, message);
  }
  return response;
}
