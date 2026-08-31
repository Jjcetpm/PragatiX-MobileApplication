import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/error/error_mapper.dart';

class ErrorHandler {
  /// Checks whether an exception or error message represents a network/connectivity failure.
  static bool isNetworkError(dynamic error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error is HandshakeException) {
      return true;
    }
    final errStr = error.toString().toLowerCase();
    return errStr.contains('socketexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('network error') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('connection closed') ||
        errStr.contains('connection timed out') ||
        errStr.contains('connection failed') ||
        errStr.contains('failed to connect') ||
        errStr.contains('handshakeexception') ||
        errStr.contains('httpexception') ||
        errStr.contains('timeoutexception') ||
        errStr.contains('timed out') ||
        errStr.contains('no internet') ||
        errStr.contains('no address associated') ||
        errStr.contains('xmlhttprequest') ||
        errStr.contains('host is down') ||
        errStr.contains('no route to host') ||
        errStr.contains('broken pipe') ||
        errStr.contains('software caused connection abort') ||
        errStr.contains('os error:');
  }

  /// Extracts a clean, user-friendly error message from any error or exception.
  static String getErrorMessage(dynamic error) {
    if (error == null) return "Unexpected error occurred.";

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return "Session expired. Please login again.";
      } else if (error.statusCode == 403) {
        return "You do not have permission to perform this action.";
      } else if (error.statusCode == 404) {
        return "Requested resource was not found.";
      } else if (error.statusCode >= 500) {
        if (error.message.isNotEmpty &&
            !error.message.contains("Exception") &&
            !error.message.contains("500") &&
            !error.message.contains("<html>")) {
          return error.message;
        }
        return "Unexpected server error. Please contact the administrator.";
      } else {
        return error.message;
      }
    }

    if (isNetworkError(error)) {
      return "Network Error: Please check your internet connection.";
    }

    final errStr = error.toString().replaceAll("Exception: ", "").trim();
    if (isNetworkError(errStr)) {
      return "Network Error: Please check your internet connection.";
    }

    return errStr.isNotEmpty ? errStr : "Unexpected error occurred.";
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
