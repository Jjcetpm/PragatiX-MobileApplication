import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/error/pages/no_internet_page.dart';
import 'package:pragatix/core/error/pages/server_unavailable_page.dart';
import 'package:pragatix/core/error/pages/request_timeout_page.dart';
import 'package:pragatix/core/error/pages/unauthorized_page.dart';
import 'package:pragatix/core/error/pages/permission_denied_page.dart';
import 'package:pragatix/core/error/pages/not_found_page.dart';
import 'package:pragatix/core/error/pages/empty_data_page.dart';
import 'package:pragatix/core/error/pages/server_error_page.dart';
import 'package:pragatix/core/error/pages/maintenance_page.dart';
import 'package:pragatix/core/error/pages/upload_error_page.dart';
import 'package:pragatix/core/error/pages/download_error_page.dart';
import 'package:pragatix/core/error/pages/unexpected_error_page.dart';

class AppErrorMapper {
  /// Converts any Exception or Error into an AppErrorType
  static AppErrorType fromException(dynamic error) {
    if (error is SocketException) {
      return AppErrorType.serverUnavailable; // Typically connection refused
    }

    if (error is TimeoutException) {
      return AppErrorType.requestTimeout;
    }

    if (error.toString().contains('SocketException') || error.toString().contains('Connection refused')) {
      return AppErrorType.serverUnavailable;
    }

    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return AppErrorType.unauthorized;
        case 403:
          return AppErrorType.permissionDenied;
        case 404:
          return AppErrorType.notFound;
        case 408:
        case 504:
          return AppErrorType.requestTimeout;
        case 502:
        case 503:
          // Check if error message explicitly implies maintenance
          if (error.message.toLowerCase().contains('maintenance')) {
            return AppErrorType.maintenance;
          }
          return AppErrorType.serverUnavailable;
        case 500:
          return AppErrorType.serverError;
        default:
          return AppErrorType.unexpected;
      }
    }

    return AppErrorType.unexpected;
  }

  /// Returns the corresponding Flutter Widget for a given AppErrorType
  static Widget getErrorPage(
    AppErrorType type, {
    VoidCallback? onRetry,
    VoidCallback? onBack,
    VoidCallback? onHome,
    String? customMessage,
    String? customTitle,
    IconData? customIcon,
  }) {
    switch (type) {
      case AppErrorType.noInternet:
        return NoInternetPage(onRetry: onRetry, onBack: onBack);
      case AppErrorType.serverUnavailable:
        return ServerUnavailablePage(onRetry: onRetry, onBack: onBack);
      case AppErrorType.requestTimeout:
        return RequestTimeoutPage(onRetry: onRetry, onBack: onBack);
      case AppErrorType.unauthorized:
        return const UnauthorizedPage();
      case AppErrorType.permissionDenied:
        return PermissionDeniedPage(onBack: onBack, onHome: onHome);
      case AppErrorType.notFound:
        return NotFoundPage(onBack: onBack, onHome: onHome);
      case AppErrorType.emptyData:
        return EmptyDataPage(
          title: customTitle,
          message: customMessage,
          icon: customIcon,
          primaryButtonText: onRetry != null ? 'Refresh' : null,
          onPrimaryPressed: onRetry,
        );
      case AppErrorType.serverError:
        return ServerErrorPage(onRetry: onRetry, onBack: onBack);
      case AppErrorType.maintenance:
        return MaintenancePage(onRetry: onRetry, onHome: onHome, maintenanceMessage: customMessage);
      case AppErrorType.uploadError:
        return UploadErrorPage(onRetry: onRetry, onChooseAnother: onBack, detailedReason: customMessage);
      case AppErrorType.downloadError:
        return DownloadErrorPage(onRetry: onRetry, onBack: onBack);
      case AppErrorType.unexpected:
      default:
        return UnexpectedErrorPage(onRetry: onRetry, onHome: onHome);
    }
  }
}
