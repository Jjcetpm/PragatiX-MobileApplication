import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/config/app_version_config.dart';
import 'package:pragatix/core/models/app_version_info.dart';

/// Centralized service to manage App Version Gating & Force Updates.
class AppVersionService {
  static final AppVersionService instance = AppVersionService._internal();
  AppVersionService._internal();

  /// Reactive notifier indicating whether the student is blocked by a mandatory update.
  final ValueNotifier<bool> isUpdateRequired = ValueNotifier<bool>(false);

  /// Reactive notifier holding the fetched update policy details.
  final ValueNotifier<AppVersionInfo?> updateInfo = ValueNotifier<AppVersionInfo?>(null);

  /// Reactive notifier indicating whether a version check is currently active.
  final ValueNotifier<bool> isChecking = ValueNotifier<bool>(false);

  /// Performs a version check against the backend.
  Future<bool> checkAppVersion({Duration timeout = const Duration(seconds: 7)}) async {
    if (isChecking.value) return isUpdateRequired.value;
    isChecking.value = true;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/app/version/check').replace(
        queryParameters: {
          'platform': 'ANDROID',
          'version': AppVersionConfig.currentVersion,
          'buildNumber': AppVersionConfig.currentBuildNumber.toString(),
        },
      );

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final info = AppVersionInfo.fromJson(body['data']);
          updateInfo.value = info;

          // Check if update is required
          final bool required = info.updateRequired ||
              (info.forceUpdate &&
                  (AppVersionConfig.currentBuildNumber < info.minBuildNumber ||
                      _isOutdated(AppVersionConfig.currentVersion, info.minVersion)));

          isUpdateRequired.value = required;
          debugPrint('[AppVersionService] Version checked: current=${AppVersionConfig.currentVersion}+${AppVersionConfig.currentBuildNumber}, min=${info.minVersion}+${info.minBuildNumber}, updateRequired=$required');
          return required;
        }
      }
    } catch (e) {
      debugPrint('[AppVersionService] Version check failed (offline/error): $e');
      // Do not block student on offline/transient network errors
    } finally {
      isChecking.value = false;
    }

    return isUpdateRequired.value;
  }

  /// Helper to compare semantic versions: returns true if client < min
  static bool _isOutdated(String client, String min) {
    try {
      final cParts = client.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map(int.parse).toList();
      final mParts = min.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map(int.parse).toList();

      final len = cParts.length > mParts.length ? cParts.length : mParts.length;
      for (int i = 0; i < len; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final m = i < mParts.length ? mParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
    } catch (_) {}
    return false;
  }
}

