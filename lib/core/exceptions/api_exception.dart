import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/core/services/server_status_service.dart';
import 'package:pragatix/core/crypto/transit_crypto.dart';

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
  http.Response effectiveResponse = response;

  if (response.body.isNotEmpty && TransitCrypto.containsEncryptedData(response.body)) {
    try {
      final decoded = jsonDecode(response.body);
      final decrypted = await TransitCrypto.decryptPayload(decoded);
      final decryptedBody = jsonEncode(decrypted);
      effectiveResponse = http.Response(
        decryptedBody,
        response.statusCode,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
        request: response.request,
      );
    } catch (e) {
      debugPrint('TransitCrypto: Error decrypting response payload: $e');
    }
  }

  if (effectiveResponse.statusCode == 401) {
    // Check if the request is an auth endpoint (like verify-otp), in which case it's not a session expiry
    final path = effectiveResponse.request?.url.path ?? '';
    if (!path.contains('/auth/')) {
      // Token expired — auto-logout
      _handleSessionExpired();
      throw ApiException(401, 'Session expired. Please login again.');
    }
  }

  // Handle true gateway downtime (502, 503, 504)
  if (effectiveResponse.statusCode == 502 || effectiveResponse.statusCode == 503 || effectiveResponse.statusCode == 504) {
    ServerStatusService.instance.setMaintenanceMode(true);
    throw ServerMaintenanceException('Server is currently under maintenance. Please try again later.');
  }

  if (effectiveResponse.statusCode >= 400 || (effectiveResponse.body.isNotEmpty && effectiveResponse.body.trim().startsWith('<'))) {
    String message = 'An error occurred';
    try {
      if (effectiveResponse.body.trim().startsWith('<')) {
        // Backend offline / gateway error returned HTML
        ServerStatusService.instance.setMaintenanceMode(true);
        throw ServerMaintenanceException('Please try again later.');
      } else {
        final data = jsonDecode(effectiveResponse.body);
        message = data['message'] ?? data['error'] ?? message;
      }
    } on ServerMaintenanceException {
      rethrow;
    } catch (_) {}

    final lowerMsg = message.toLowerCase();
    if (lowerMsg.contains('server is currently under maintenance') ||
        lowerMsg.contains('server maintenance') ||
        lowerMsg.contains('service unavailable') ||
        lowerMsg.contains('bad gateway')) {
      ServerStatusService.instance.setMaintenanceMode(true);
      throw ServerMaintenanceException('Please try again later.');
    }

    final statusCode = effectiveResponse.statusCode < 400 ? 500 : effectiveResponse.statusCode;
    throw ApiException(statusCode, message);
  }
  return effectiveResponse;
}

