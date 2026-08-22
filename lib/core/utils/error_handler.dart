import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/error/error_mapper.dart';

class ErrorHandler {
  static void showSnackBar(BuildContext context, dynamic error) {
    String message = "Unexpected error occurred.";
    if (error is ApiException) {
      if (error.statusCode == 401) {
        message = "Session expired. Please login again.";
      } else if (error.statusCode == 403) {
        message = "You do not have permission to perform this action.";
      } else if (error.statusCode == 404) {
        message = "Requested resource was not found.";
      } else if (error.statusCode >= 500) {
        message = "Unexpected server error. Please contact the administrator.";
      } else {
        // For 400, 409, 422, etc., display the backend message verbatim
        message = error.message;
      }
    } else if (error is SocketException ||
        error is TimeoutException ||
        error.toString().contains("SocketException") ||
        error.toString().contains("TimeoutException") ||
        error.toString().contains("Connection refused")) {
      message = "Network Error: Please check your internet connection.";
    } else {
      message = error.toString().replaceAll("Exception: ", "");
    }

    // Check if widget tree is still mounted before showing snackbar
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
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
