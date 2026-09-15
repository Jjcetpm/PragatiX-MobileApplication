import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/crypto/transit_crypto.dart';

/// Keys used in SharedPreferences for session persistence.
class _SessionKeys {
  static const String token = 'auth_token';
  static const String role = 'auth_role';
  static const String user = 'auth_user';
  static const String academicYear = 'auth_academic_year';
  /// ISO-8601 string of when the login happened (used for 16-hour expiry check).
  static const String sessionExpiry = 'auth_session_expiry';
}

/// Session duration: 16 hours from login time.
const Duration _sessionDuration = Duration(hours: 16);

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  Map<String, dynamic>? _currentUser;
  String? _selectedAcademicYear;

  // â”€â”€ Getters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ Login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Called after a successful OTP verification.
  /// Persists ALL session data including the 16-hour expiry timestamp.
  Future<void> login(String token, String role, Map<String, dynamic> user) async {
    _token = token;
    _role = role;
    final decryptedUser = await TransitCrypto.decryptPayload(user);
    _currentUser = decryptedUser is Map<String, dynamic> ? decryptedUser : user;

    // Calculate session expiry: now + 16 hours
    final sessionExpiry = DateTime.now().add(_sessionDuration);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_SessionKeys.token, token);
    await prefs.setString(_SessionKeys.role, role);
    await prefs.setString(_SessionKeys.user, jsonEncode(_currentUser));
    await prefs.setString(_SessionKeys.sessionExpiry, sessionExpiry.toIso8601String());

    notifyListeners();
  }

  // â”€â”€ Academic Year â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> setSelectedAcademicYear(String? year) async {
    _selectedAcademicYear = year;
    final prefs = await SharedPreferences.getInstance();
    if (year != null) {
      await prefs.setString(_SessionKeys.academicYear, year);
    } else {
      await prefs.remove(_SessionKeys.academicYear);
    }
    notifyListeners();
  }

  // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Explicit logout: clears ALL session data immediately.
  /// After this, reopening the app MUST show Login.
  Future<void> logout() async {
    _token = null;
    _role = null;
    _currentUser = null;
    _selectedAcademicYear = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipes everything including session expiry
    notifyListeners();
  }

  // â”€â”€ Startup Session Restore â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Called once at app startup (before runApp or in main).
  ///
  /// Strategy:
  ///   1. Read stored session from SharedPreferences.
  ///   2. Check if session is within 16-hour window (no network needed).
  ///   3. If valid: restore in-memory state â†’ show dashboard immediately.
  ///   4. If expired or missing: clear storage â†’ show Login.
  ///   5. After restoring: silently verify token in background.
  ///      Only logs out on 401 (real token expiry). Ignores network errors.
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_SessionKeys.token);
    final expiryStr = prefs.getString(_SessionKeys.sessionExpiry);

    // â”€â”€ Guard: missing token â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (savedToken == null || savedToken.isEmpty) {
      await logout();
      return;
    }

    // â”€â”€ Guard: 16-hour local session expiry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null || DateTime.now().isAfter(expiry)) {
        // Session has expired locally â€” clear and go to Login
        await logout();
        return;
      }
    } else {
      // No expiry stored (old install before this update) â€” treat as expired
      await logout();
      return;
    }

    // â”€â”€ Restore session from local storage (no network call) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final savedRole = prefs.getString(_SessionKeys.role);
    final savedUserJson = prefs.getString(_SessionKeys.user);
    final savedYear = prefs.getString(_SessionKeys.academicYear);

    if (savedUserJson == null || savedUserJson.isEmpty) {
      await logout();
      return;
    }

    try {
      _token = savedToken;
      _role = savedRole;
      _selectedAcademicYear = savedYear;
      final rawUser = jsonDecode(savedUserJson) as Map<String, dynamic>;
      if (TransitCrypto.containsEncryptedData(savedUserJson)) {
        final decrypted = await TransitCrypto.decryptPayload(rawUser);
        _currentUser = decrypted is Map<String, dynamic> ? decrypted : rawUser;
        await prefs.setString(_SessionKeys.user, jsonEncode(_currentUser));
      } else {
        _currentUser = rawUser;
      }
      notifyListeners(); // — Dashboard shown immediately, no flicker
    } catch (_) {
      // Corrupted stored data — force re-login
      await logout();
      return;
    }

    // ── Background verification (does NOT block startup) ──
    // Only logs out on 401 (JWT truly expired/revoked by server).
    // All other errors (network, 500, timeout) are ignored to preserve session.
    _silentVerify(savedToken, prefs);
  }

  /// Silently verifies the JWT against the server after session is restored.
  /// - 401 â†’ logout (JWT expired or revoked)
  /// - 200 â†’ refresh cached user data
  /// - anything else â†’ keep session alive (network issues should not log user out)
  void _silentVerify(String token, SharedPreferences prefs) {
    http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .then((response) async {
          if (response.statusCode == 401) {
            // JWT truly invalid/expired by the server â€” clear session
            await logout();
            return;
          }
          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              if (data['success'] == true && data['data'] != null) {
                // Refresh in-memory user data from server (latest roles, etc.)
                _currentUser = data['data'] as Map<String, dynamic>;
                await prefs.setString(_SessionKeys.user, jsonEncode(_currentUser));
                notifyListeners();
              }
            } catch (_) {
              // JSON parse error â€” keep existing session data unchanged
            }
          }
          // 500, 503, etc.: keep session alive â€” these are server/network issues
        })
        .catchError((_) {
          // Network unavailable â€” user stays logged in
          // The 16-hour local check already ran and passed
        });
  }

  Future<void> refreshToken() async {
    // TODO: implement refresh token if backend adds refresh endpoint
  }
}