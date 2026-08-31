import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Encapsulates the evaluation result of the device debugging security check.
class SecurityCheckResult {
  final bool isDebuggingEnabled;
  final bool isUsbDebugging;
  final bool isWirelessDebugging;
  final bool isReleaseMode;
  final bool hasError;
  final String? errorMessage;

  const SecurityCheckResult({
    required this.isDebuggingEnabled,
    this.isUsbDebugging = false,
    this.isWirelessDebugging = false,
    this.isReleaseMode = false,
    this.hasError = false,
    this.errorMessage,
  });

  factory SecurityCheckResult.safe({bool isReleaseMode = false}) {
    return SecurityCheckResult(
      isDebuggingEnabled: false,
      isUsbDebugging: false,
      isWirelessDebugging: false,
      isReleaseMode: isReleaseMode,
    );
  }

  factory SecurityCheckResult.blocked({
    required bool isUsbDebugging,
    required bool isWirelessDebugging,
  }) {
    return SecurityCheckResult(
      isDebuggingEnabled: true,
      isUsbDebugging: isUsbDebugging,
      isWirelessDebugging: isWirelessDebugging,
      isReleaseMode: true,
    );
  }

  factory SecurityCheckResult.error(String message) {
    return SecurityCheckResult(
      isDebuggingEnabled: false,
      hasError: true,
      errorMessage: message,
      isReleaseMode: kReleaseMode,
    );
  }

  @override
  String toString() {
    return 'SecurityCheckResult(isDebuggingEnabled: $isDebuggingEnabled, USB: $isUsbDebugging, Wireless: $isWirelessDebugging, isReleaseMode: $isReleaseMode, hasError: $hasError)';
  }
}

/// Service dedicated to checking and enforcing device security policies
/// exclusively in production/release builds.
class ProductionSecurityService {
  static const MethodChannel _channel = MethodChannel('com.pragatix/security');

  /// Singleton instance
  static final ProductionSecurityService instance = ProductionSecurityService._internal();

  ProductionSecurityService._internal();

  factory ProductionSecurityService() => instance;

  /// Observable security status that UI components can listen to without duplicate dialogs.
  final ValueNotifier<SecurityCheckResult?> statusNotifier = ValueNotifier<SecurityCheckResult?>(null);

  SecurityCheckResult? get currentStatus => statusNotifier.value;

  /// Performs the debugging security check.
  ///
  /// - In Debug / Testing builds (`!kReleaseMode`): Skips the check entirely to allow
  ///   developers to debug over USB and Wi-Fi seamlessly.
  /// - In Release builds (`kReleaseMode` / Production APK & AAB): Checks native Android
  ///   system settings for active USB and Wireless debugging.
  Future<SecurityCheckResult> checkDebuggingState() async {
    // 1. Check build mode: Bypassed in debug and development builds
    if (!kReleaseMode) {
      debugPrint('[Security] Debugging protection skipped in debug build');
      final result = SecurityCheckResult.safe(isReleaseMode: false);
      statusNotifier.value = result;
      return result;
    }

    // 2. Production build: Execute native Android platform security check
    debugPrint('[Security] Release build detected. Debugging check started...');
    try {
      final dynamic rawResult = await _channel.invokeMethod('isDebuggingEnabled');
      
      if (rawResult is Map) {
        final isDebugging = (rawResult['isDebuggingEnabled'] as bool?) ?? false;
        final isUsb = (rawResult['isUsbDebuggingEnabled'] as bool?) ?? false;
        final isWireless = (rawResult['isWirelessDebuggingEnabled'] as bool?) ?? false;

        debugPrint('[Security] USB debugging: ${isUsb ? "enabled" : "disabled"}');
        debugPrint('[Security] Wireless debugging: ${isWireless ? "enabled" : "disabled"}');

        final result = isDebugging
            ? SecurityCheckResult.blocked(isUsbDebugging: isUsb, isWirelessDebugging: isWireless)
            : SecurityCheckResult.safe(isReleaseMode: true);

        if (isDebugging) {
          debugPrint('[Security] Application access blocked');
        } else {
          debugPrint('[Security] Device verified secure. Debugging disabled.');
        }

        statusNotifier.value = result;
        return result;
      } else if (rawResult is bool) {
        final result = rawResult
            ? SecurityCheckResult.blocked(isUsbDebugging: rawResult, isWirelessDebugging: false)
            : SecurityCheckResult.safe(isReleaseMode: true);
        statusNotifier.value = result;
        return result;
      }

      final safeFallback = SecurityCheckResult.safe(isReleaseMode: true);
      statusNotifier.value = safeFallback;
      return safeFallback;
    } on PlatformException catch (e) {
      debugPrint('[Security] Platform exception during debugging check: ${e.message}');
      final errResult = SecurityCheckResult.error(e.message ?? 'Unknown platform exception');
      statusNotifier.value = errResult;
      return errResult;
    } catch (e) {
      debugPrint('[Security] Unexpected error during debugging check: $e');
      final errResult = SecurityCheckResult.error(e.toString());
      statusNotifier.value = errResult;
      return errResult;
    }
  }

  /// Opens the Android Developer Options settings screen for the user.
  Future<bool> openSettings() async {
    try {
      final bool? opened = await _channel.invokeMethod<bool>('openDevelopmentSettings');
      return opened ?? false;
    } catch (e) {
      debugPrint('[Security] Failed to open developer settings: $e');
      return false;
    }
  }
}
