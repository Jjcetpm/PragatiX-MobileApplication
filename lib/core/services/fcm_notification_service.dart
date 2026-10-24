import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/features/announcements/pages/announcement_details_page.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';

import 'package:provider/provider.dart';
import 'package:pragatix/features/announcements/providers/notification_provider.dart';

/// Top-level background message handler entry point for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM] Handling background message: ${message.messageId}');
}

class FcmNotificationService {
  FcmNotificationService._internal();
  static final FcmNotificationService instance = FcmNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _lastRegisteredToken;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Request notification permission (critical for Android 13+ & iOS)
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission authorization status: ${settings.authorizationStatus}');

      // 2. Set foreground presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Listen to foreground incoming messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground notification received: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // 4. Listen to notification clicks when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification clicked in background: ${message.data}');
        _navigateToAnnouncement(message);
      });

      // 5. Check if app was opened from terminated state by tapping notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App launched from cold start by tapping notification: ${initialMessage.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToAnnouncement(initialMessage);
        });
      }

      // 6. Listen to token refresh events
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Device token refreshed');
        registerTokenWithBackend(newToken);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Error initializing FCM notification service: $e');
    }
  }

  /// Displays an in-app banner or dialog when an announcement arrives while app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final context = NavigatorService.navigatorKey.currentContext;
    if (context == null) return;

    // Refresh unread notifications count if NotificationProvider is available
    try {
      context.read<NotificationProvider>().fetchUnreadCount();
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    } catch (_) {}

    final title = message.notification?.title ?? message.data['title'] ?? 'New Announcement';
    final subject = message.data['subject'] ?? '';
    final body = message.notification?.body ?? message.data['message'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF0F172A),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF818CF8), width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subject.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA5B4FC),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFCBD5E1),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: const Color(0xFF38BDF8),
          onPressed: () {
            _navigateToAnnouncement(message);
          },
        ),
      ),
    );
  }

  /// Navigates to AnnouncementDetailsPage
  void _navigateToAnnouncement(RemoteMessage message) {
    final nav = NavigatorService.navigatorKey.currentState;
    if (nav == null) return;

    final title = message.notification?.title ?? message.data['title'] ?? 'Campus Announcement';
    final subject = message.data['subject'] ?? '';
    final body = message.data['message'] ?? message.notification?.body ?? '';
    final createdAt = message.data['created_at'];

    nav.push(
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailsPage(
          title: title,
          subject: subject,
          message: body,
          createdAt: createdAt,
        ),
      ),
    );
  }

  /// Registers or refreshes the FCM device token with the Spring Boot backend
  Future<void> registerTokenWithBackend([String? token]) async {
    try {
      token ??= await _fcm.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] No device token available to register');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) {
        debugPrint('[FCM] User not authenticated yet; deferring token registration');
        return;
      }

      // Avoid redundant registration if token hasn't changed
      if (_lastRegisteredToken == token) {
        return;
      }

      final deviceType = Platform.isAndroid ? 'ANDROID' : (Platform.isIOS ? 'IOS' : 'OTHER');
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/devices/token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'deviceType': deviceType,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastRegisteredToken = token;
        debugPrint('[FCM] Device token registered successfully with backend');
      } else {
        debugPrint('[FCM] Failed to register token with backend (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[FCM] Exception registering token with backend: $e');
    }
  }

  /// Unregisters the current device token upon user logout
  Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/devices/token');
      await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
        }),
      );

      _lastRegisteredToken = null;
      debugPrint('[FCM] Device token unregistered from backend on logout');
    } catch (e) {
      debugPrint('[FCM] Exception unregistering token on logout: $e');
    }
  }
}
