import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/features/announcements/pages/announcement_details_page.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/announcements/providers/notification_provider.dart';

/// Central flutter_local_notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Android notification channel for PragatiX announcements
const AndroidNotificationChannel pragatixNotificationChannel =
    AndroidNotificationChannel(
  'pragatix_announcements',
  'PragatiX Announcements',
  description: 'Campus announcements and notifications with PragatiX branding',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Displays a high-importance local notification with the custom small monochrome
/// icon ('ic_notification') and exact full-colour PragatiX logo ('pragatix_logo_badge')
@pragma('vm:entry-point')
Future<void> showLocalNotificationFromRemote(RemoteMessage message) async {
  try {
    final title = message.data['title'] ??
        message.notification?.title ??
        'PragatiX Announcement';
    final subject = message.data['subject'] ?? '';
    final messageText =
        message.data['message'] ?? message.notification?.body ?? '';

    final String body = messageText.isNotEmpty ? messageText : subject;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pragatix_announcements',
      'PragatiX Announcements',
      channelDescription:
          'Campus announcements and notifications with PragatiX branding',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      color: const Color(0xFF11998E),
      largeIcon: const DrawableResourceAndroidBitmap('pragatix_logo_badge'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: subject.isNotEmpty ? subject : null,
        htmlFormatBigText: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final int notificationId = message.data['id'] != null
        ? int.tryParse(message.data['id'].toString()) ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000)
        : DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final payload = jsonEncode(message.data);

    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: title,
      body: subject.isNotEmpty ? subject : body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  } catch (e) {
    debugPrint('[FCM] Error displaying local notification: $e');
  }
}

/// Top-level background message handler entry point for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM] Handling background message: ${message.messageId}');

  // CRITICAL: Prevent duplicate notifications.
  // If message.notification != null, Google Play Services / Android OS
  // automatically posts the notification to the system tray.
  // We ONLY call showLocalNotificationFromRemote when message.notification == null (data-only message),
  // which ensures full-colour largeIcon display in background without duplicating.
  if (message.notification == null) {
    await showLocalNotificationFromRemote(message);
  }
}

class FcmNotificationService {
  FcmNotificationService._internal();
  static final FcmNotificationService instance =
      FcmNotificationService._internal();

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

      debugPrint(
          '[FCM] Permission authorization status: ${settings.authorizationStatus}');

      // 2. Set foreground presentation options
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize flutter_local_notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data =
                  jsonDecode(response.payload!) as Map<String, dynamic>;
              _navigateToAnnouncementFromData(data);
            } catch (e) {
              debugPrint('[FCM] Error navigating from notification tap: $e');
            }
          }
        },
      );

      // 4. Create high-importance Android notification channel
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(pragatixNotificationChannel);

      // 5. Check if app was opened from terminated state by tapping a local notification
      final NotificationAppLaunchDetails? launchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final payloadStr = launchDetails.notificationResponse!.payload!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final Map<String, dynamic> data =
                jsonDecode(payloadStr) as Map<String, dynamic>;
            _navigateToAnnouncementFromData(data);
          } catch (e) {
            debugPrint('[FCM] Error parsing cold start local payload: $e');
          }
        });
      }

      // 6. Listen to foreground incoming messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            '[FCM] Foreground notification received: ${message.notification?.title ?? message.data['title']}');
        _handleForegroundMessage(message);
      });

      // 7. Listen to notification clicks when app is in background (FCM system tray notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification clicked in background: ${message.data}');
        _navigateToAnnouncement(message);
      });

      // 8. Check if app was opened from terminated state by tapping FCM system notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '[FCM] App launched from cold start by tapping FCM notification: ${initialMessage.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToAnnouncement(initialMessage);
        });
      }

      // 9. Listen to token refresh events
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Device token refreshed');
        registerTokenWithBackend(newToken);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Error initializing FCM notification service: $e');
    }
  }

  /// Displays in-app banner SnackBar AND posts rich system notification with PragatiX full-colour logo
  void _handleForegroundMessage(RemoteMessage message) {
    final context = NavigatorService.navigatorKey.currentContext;

    // Refresh unread notifications count if NotificationProvider is available
    if (context != null) {
      try {
        context.read<NotificationProvider>().fetchUnreadCount();
        context.read<NotificationProvider>().fetchNotifications(refresh: true);
      } catch (_) {}
    }

    // Always post to Android system drawer with small icon & full-colour large icon
    showLocalNotificationFromRemote(message);

    // Show floating in-app banner SnackBar if UI is mounted
    if (context != null) {
      _showInAppBanner(context, message);
    }
  }

  void _showInAppBanner(BuildContext context, RemoteMessage message) {
    final title = message.data['title'] ??
        message.notification?.title ??
        'New Announcement';
    final subject = message.data['subject'] ?? '';
    final body =
        message.data['message'] ?? message.notification?.body ?? '';

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
                  errorBuilder: (context, error, stackTrace) => const Icon(
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

  /// Navigates to AnnouncementDetailsPage from RemoteMessage
  void _navigateToAnnouncement(RemoteMessage message) {
    final nav = NavigatorService.navigatorKey.currentState;
    if (nav == null) return;

    final title = message.data['title'] ??
        message.notification?.title ??
        'Campus Announcement';
    final subject = message.data['subject'] ?? '';
    final body =
        message.data['message'] ?? message.notification?.body ?? '';
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

  /// Navigates to AnnouncementDetailsPage from Map data payload
  void _navigateToAnnouncementFromData(Map<String, dynamic> data) {
    final nav = NavigatorService.navigatorKey.currentState;
    if (nav == null) return;

    final title = data['title'] ?? 'Campus Announcement';
    final subject = data['subject'] ?? '';
    final body = data['message'] ?? data['body'] ?? '';
    final createdAt = data['created_at'];

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
        debugPrint(
            '[FCM] User not authenticated yet; deferring token registration');
        return;
      }

      // Avoid redundant registration if token hasn't changed
      if (_lastRegisteredToken == token) {
        return;
      }

      final deviceType = kIsWeb
          ? 'WEB'
          : (Platform.isAndroid ? 'ANDROID' : (Platform.isIOS ? 'IOS' : 'OTHER'));
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
        debugPrint(
            '[FCM] Device token registered successfully with backend');
      } else {
        debugPrint(
            '[FCM] Failed to register token with backend (Status: ${response.statusCode})');
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
