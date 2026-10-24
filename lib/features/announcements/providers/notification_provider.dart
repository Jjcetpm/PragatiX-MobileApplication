import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/announcements/models/in_app_notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<InAppNotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<InAppNotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (_) {
      return null;
    }
  }

  /// Fetches unread count quickly (lightweight)
  Future<void> fetchUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/unread-count');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final countVal = decoded['data']['unreadCount'];
          _unreadCount = countVal is int ? countVal : int.tryParse(countVal?.toString() ?? '0') ?? 0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error fetching unread count: $e');
    }
  }

  /// Fetches full notification list
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (!refresh && _notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications?page=0&size=50');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final content = decoded['data']['content'] ?? [];
          if (content is List) {
            _notifications = content
                .map((item) => InAppNotificationModel.fromJson(item as Map<String, dynamic>))
                .toList();

            _unreadCount = _notifications.where((n) => !n.isRead).length;
            _errorMessage = null;
          }
        }
      } else {
        _errorMessage = 'Failed to load notifications (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error fetching notifications: $e');
      _errorMessage = 'Could not load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a specific notification as read
  Future<void> markAsRead(int notificationId) async {
    // Optimistic local update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/$notificationId/read');
      await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking notification #$notificationId as read: $e');
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead() async {
    // Optimistic local update
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed || _unreadCount > 0) {
      _unreadCount = 0;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/read-all');
      await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking all as read: $e');
    }
  }
}
