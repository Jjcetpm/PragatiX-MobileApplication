import 'package:flutter/material.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/error/error_mapper.dart';

class ErrorClassification {
  final NetworkErrorCategory category;
  final String title;
  final String message;

  const ErrorClassification({
    required this.category,
    required this.title,
    required this.message,
  });

  bool get isMaintenance =>
      category == NetworkErrorCategory.serverUnavailable ||
      category == NetworkErrorCategory.serverError;

  bool get isNoInternet => category == NetworkErrorCategory.noInternet;
  bool get isClientError => category == NetworkErrorCategory.clientError;
  bool get isSuccess => category == NetworkErrorCategory.success;
}

class ErrorHandler {
  /// Checks whether an exception or error indicates the device has no internet connection.
  static bool isDeviceOfflineError(dynamic error) {
    if (error is NoInternetException) return true;
    final errStr = error.toString().toLowerCase();
    return errStr.contains('no internet') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('network is down') ||
        errStr.contains('no route to host') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('enetunreach') ||
        errStr.contains('enetdown');
  }

  /// Checks whether an exception indicates the backend server is offline, unreachable, or under maintenance.
  static bool isServerMaintenanceError(dynamic error) {
    if (error is ServerMaintenanceException) return true;
    if (error is ApiException) {
      if (error.statusCode >= 500) {
        return true;
      }
      final lowerMsg = error.message.toLowerCase();
      if (lowerMsg.contains('maintenance') ||
          lowerMsg.contains('bad gateway') ||
          lowerMsg.contains('service unavailable') ||
          lowerMsg.contains('gateway timeout') ||
          lowerMsg.contains('html')) {
        return true;
      }
    }
    final errStr = error.toString().toLowerCase();
    return errStr.contains('maintenance') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('connection closed') ||
        errStr.contains('broken pipe') ||
        errStr.contains('host is down') ||
        errStr.contains('server unavailable') ||
        errStr.contains('timed out') ||
        errStr.contains('timeout') ||
        errStr.contains('bad gateway') ||
        errStr.contains('service unavailable') ||
        errStr.contains('software caused connection abort') ||
        errStr.contains('failed to connect') ||
        errStr.contains('connection failed') ||
        errStr.contains('clientexception');
  }

  /// Checks whether an exception represents a network/connectivity failure.
  static bool isNetworkError(dynamic error) {
    return isDeviceOfflineError(error) || isServerMaintenanceError(error);
  }

  /// Centralized classification mechanism
  /// Conceptually maps to:
  /// - NO_INTERNET
  /// - SERVER_UNAVAILABLE
  /// - SERVER_ERROR
  /// - CLIENT_ERROR
  /// - SUCCESS
  static ErrorClassification classify(dynamic error) {
    if (error == null) {
      return const ErrorClassification(
        category: NetworkErrorCategory.success,
        title: 'Success',
        message: '',
      );
    }

    // 1. Device Internet OFF
    if (error is NoInternetException || isDeviceOfflineError(error)) {
      return const ErrorClassification(
        category: NetworkErrorCategory.noInternet,
        title: 'No Internet Connection',
        message: 'Please check your internet connection and try again.',
      );
    }

    // 2. API Exceptions (HTTP responses from backend)
    if (error is ApiException) {
      // 502, 503, 504 -> Server Maintenance
      if (error.statusCode == 502 || error.statusCode == 503 || error.statusCode == 504) {
        return const ErrorClassification(
          category: NetworkErrorCategory.serverUnavailable,
          title: 'Server is currently under maintenance.',
          message: 'Please try again later.',
        );
      }
      // 500 -> Server Error, display actual backend message
      if (error.statusCode >= 500) {
        return ErrorClassification(
          category: NetworkErrorCategory.serverError,
          title: 'Server Error',
          message: error.message.isNotEmpty ? error.message : 'An internal server error occurred. Please try again.',
        );
      }
      // 4xx -> Client Errors (preserve authentication/authorization)
      if (error.statusCode == 401) {
        return const ErrorClassification(
          category: NetworkErrorCategory.clientError,
          title: 'Session Expired',
          message: 'Session expired. Please login again.',
        );
      }
      if (error.statusCode == 403) {
        return const ErrorClassification(
          category: NetworkErrorCategory.clientError,
          title: 'Permission Denied',
          message: 'You do not have permission to perform this action.',
        );
      }
      if (error.statusCode == 404) {
        return const ErrorClassification(
          category: NetworkErrorCategory.clientError,
          title: 'Not Found',
          message: 'Requested resource was not found.',
        );
      }
      return ErrorClassification(
        category: NetworkErrorCategory.clientError,
        title: 'Request Error',
        message: error.message.isNotEmpty ? error.message : 'An error occurred with your request.',
      );
    }

    // 3. Server Unavailable / Maintenance (TCP connection refused, timeout, handshake failure)
    if (error is ServerMaintenanceException || isServerMaintenanceError(error)) {
      return const ErrorClassification(
        category: NetworkErrorCategory.serverUnavailable,
        title: 'Server is currently under maintenance.',
        message: 'Please try again later.',
      );
    }

    final errStr = error.toString().replaceAll('Exception: ', '').trim();
    if (isDeviceOfflineError(errStr)) {
      return const ErrorClassification(
        category: NetworkErrorCategory.noInternet,
        title: 'No Internet Connection',
        message: 'Please check your internet connection and try again.',
      );
    }

    return ErrorClassification(
      category: NetworkErrorCategory.clientError,
      title: 'Error',
      message: errStr.isNotEmpty ? errStr : 'An unexpected error occurred.',
    );
  }

  /// Extracts a clean, user-friendly error message from any error or exception.
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Unexpected error occurred.';
    return classify(error).message;
  }

  static void showSnackBar(
    BuildContext context,
    dynamic error, {
    Color? backgroundColor,
    bool? isSuccess,
  }) {
    String message = getErrorMessage(error);

    final lower = message.toLowerCase();
    bool detectedSuccess = isSuccess ?? false;
    if (isSuccess == null) {
      if ((lower.contains('success') ||
              lower.contains('assigned') ||
              lower.contains('created') ||
              lower.contains('updated') ||
              lower.contains('saved') ||
              lower.contains('restored') ||
              lower.contains('deleted') ||
              lower.contains('removed') ||
              lower.contains('awarded') ||
              lower.contains('approved') ||
              lower.contains('submitted') ||
              lower.contains('completed')) &&
          !lower.contains('failed') &&
          !lower.contains('error') &&
          !lower.contains('exception') &&
          !lower.contains('cannot') &&
          !lower.contains('unable') &&
          !lower.contains('not ') &&
          !lower.contains('unsuccessful')) {
        detectedSuccess = true;
      }
    }

    final effectiveBgColor = backgroundColor ??
        (detectedSuccess ? const Color(0xFF10B981) : Colors.redAccent);

    // Check if widget tree is still mounted before showing snackbar
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: effectiveBgColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Builds a full-screen error widget using the centralized error mapper.
  /// Use this for critical page-load failures (e.g., inside FutureBuilder).
  static Widget buildErrorWidget(
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onHome,
    VoidCallback? onBack,
  }) {
    final errorType = AppErrorMapper.fromException(error);
    String? customMessage;

    if (error is ApiException && errorType == AppErrorType.unexpected) {
      customMessage = error.message;
    }

    return AppErrorMapper.getErrorPage(
      errorType,
      onRetry: onRetry,
      onHome: onHome,
      onBack: onBack,
      customMessage: customMessage,
    );
  }
}
