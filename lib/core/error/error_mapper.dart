import 'package:flutter/material.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/core/error/pages/no_internet_page.dart';
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
    final classification = ErrorHandler.classify(error);

    switch (classification.category) {
      case NetworkErrorCategory.noInternet:
        return AppErrorType.noInternet;
      case NetworkErrorCategory.serverUnavailable:
      case NetworkErrorCategory.serverError:
        return AppErrorType.maintenance;
      case NetworkErrorCategory.clientError:
        if (error is ApiException) {
          if (error.statusCode == 401) return AppErrorType.unauthorized;
          if (error.statusCode == 403) return AppErrorType.permissionDenied;
          if (error.statusCode == 404) return AppErrorType.notFound;
        }
        return AppErrorType.unexpected;
      case NetworkErrorCategory.success:
        return AppErrorType.unexpected;
    }
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
      case AppErrorType.maintenance:
        return MaintenancePage(
          onRetry: onRetry,
          onHome: onHome,
          maintenanceMessage: customMessage ?? 'Please try again later.',
        );
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
      case AppErrorType.uploadError:
        return UploadErrorPage(onRetry: onRetry, onChooseAnother: onBack, detailedReason: customMessage);
      case AppErrorType.downloadError:
        return DownloadErrorPage(onRetry: onRetry, onBack: onBack);
      case AppErrorType.unexpected:
        return UnexpectedErrorPage(onRetry: onRetry, onHome: onHome);
    }
  }
}
