enum AppErrorType {
  noInternet,
  serverUnavailable,
  requestTimeout,
  unauthorized,
  permissionDenied,
  notFound,
  emptyData,
  serverError,
  maintenance,
  uploadError,
  downloadError,
  unexpected
}

/// Centralized category classification for network/backend requests
enum NetworkErrorCategory {
  noInternet,
  serverUnavailable,
  serverError,
  clientError,
  success,
}

extension NetworkErrorCategoryExt on NetworkErrorCategory {
  bool get isMaintenance =>
      this == NetworkErrorCategory.serverUnavailable ||
      this == NetworkErrorCategory.serverError;

  bool get isNoInternet => this == NetworkErrorCategory.noInternet;
  bool get isSuccess => this == NetworkErrorCategory.success;
  bool get isClientError => this == NetworkErrorCategory.clientError;
}
