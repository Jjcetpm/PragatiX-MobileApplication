import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/connectivity_utils.dart';

/// Centralized service to monitor and control the connectivity and server state.
/// Differentiates cleanly between:
/// 1. Device network is OFF -> `isNoInternetMode = true` (shows "No Internet Connection")
/// 2. Device network is ON, but backend server is OFF -> `isMaintenanceMode = true` (shows "Server is currently under maintenance")
/// 3. Normal operation -> both false
class ServerStatusService {
  static final ServerStatusService instance = ServerStatusService._internal();
  ServerStatusService._internal();

  /// Reactive notifier for global server maintenance state
  final ValueNotifier<bool> isMaintenanceMode = ValueNotifier<bool>(false);

  /// Reactive notifier for global no-internet / device offline state
  final ValueNotifier<bool> isNoInternetMode = ValueNotifier<bool>(false);

  /// Reactive notifier indicating whether a health probe / retry check is currently in progress
  final ValueNotifier<bool> isChecking = ValueNotifier<bool>(false);

  String maintenanceMessage = 'Please try again later.';
  String noInternetMessage = 'Please check your internet connection and try again.';

  /// Updates the maintenance mode state. If setting to true, automatically clears no-internet.
  void setMaintenanceMode(bool value, {String? message}) {
    if (message != null && message.isNotEmpty) {
      maintenanceMessage = message;
    }
    if (value) {
      if (isNoInternetMode.value) isNoInternetMode.value = false;
    }
    if (isMaintenanceMode.value != value) {
      isMaintenanceMode.value = value;
      debugPrint('[ServerStatusService] Maintenance mode updated: $value');
    }
  }

  /// Updates the no-internet state. If setting to true, automatically clears maintenance.
  void setNoInternetMode(bool value, {String? message}) {
    if (message != null && message.isNotEmpty) {
      noInternetMessage = message;
    }
    if (value) {
      if (isMaintenanceMode.value) isMaintenanceMode.value = false;
    }
    if (isNoInternetMode.value != value) {
      isNoInternetMode.value = value;
      debugPrint('[ServerStatusService] No-Internet mode updated: $value');
    }
  }

  /// Clears both offline modes back to normal online state.
  void setAllOnline() {
    if (isMaintenanceMode.value) isMaintenanceMode.value = false;
    if (isNoInternetMode.value) isNoInternetMode.value = false;
    debugPrint('[ServerStatusService] Connectivity restored: Online');
  }

  /// Probes the device internet and backend server host/port.
  /// - If the device has no internet -> activates NoInternetMode.
  /// - If device has internet, but backend connection fails -> activates MaintenanceMode.
  /// - If both succeed -> clears both offline modes.
  Future<bool> checkServerHealth({Duration timeout = const Duration(seconds: 8)}) async {
    if (isChecking.value) return !isMaintenanceMode.value && !isNoInternetMode.value;
    isChecking.value = true;

    try {
      // 1. Verify if device has active Internet connectivity
      final hasInternet = await checkDeviceInternetConnectivity();
      if (!hasInternet) {
        debugPrint('[ServerStatusService] Device internet is OFF -> NoInternetMode active');
        setNoInternetMode(true);
        return false;
      }

      // 2. Device has Internet! Now test TCP handshake to backend server
      final uri = Uri.tryParse(ApiConfig.baseUrl);
      final host = uri?.host ?? '10.0.20.175';
      final port = uri?.hasPort == true ? uri!.port : (uri?.scheme == 'https' ? 443 : 8080);

      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();

      // TCP 3-way handshake succeeded! Server is alive.
      setAllOnline();
      return true;
    } on SocketException catch (e) {
      debugPrint('[ServerStatusService] Server probe failed: $e');
      final msg = e.message.toLowerCase();
      final osMsg = e.osError?.message.toLowerCase() ?? '';
      final combined = '$msg $osMsg';

      if (combined.contains('network is unreachable') ||
          combined.contains('network is down') ||
          combined.contains('no route to host') ||
          combined.contains('failed host lookup')) {
        setNoInternetMode(true);
        return false;
      }

      final hasInternet = await checkDeviceInternetConnectivity();
      if (!hasInternet) {
        setNoInternetMode(true);
      } else {
        setMaintenanceMode(true);
      }
      return false;
    } catch (e) {
      debugPrint('[ServerStatusService] Unexpected server probe error: $e');
      final hasInternet = await checkDeviceInternetConnectivity();
      if (!hasInternet) {
        setNoInternetMode(true);
      } else {
        setMaintenanceMode(true);
      }
      return false;
    } finally {
      isChecking.value = false;
    }
  }
}
