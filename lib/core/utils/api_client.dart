import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as real_http;
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/services/server_status_service.dart';
import 'package:pragatix/core/utils/connectivity_utils.dart';
import 'dart:convert';
import 'package:pragatix/core/crypto/transit_crypto.dart';

export 'package:pragatix/core/crypto/transit_crypto.dart' show TransitCrypto;
export 'package:pragatix/core/exceptions/api_exception.dart'
    show ApiException, NoInternetException, ServerMaintenanceException;
export 'package:pragatix/core/utils/connectivity_utils.dart'
    show checkDeviceInternetConnectivity, isDeviceConnectedToNetwork;

typedef Response = real_http.Response;
typedef MultipartRequest = real_http.MultipartRequest;
typedef MultipartFile = real_http.MultipartFile;
typedef Client = real_http.Client;

const Duration _defaultTimeout = Duration(seconds: 25);

/// Intercepts low-level network errors and accurately differentiates:
/// 1. Device is offline -> NoInternetException
/// 2. Device has Internet, but backend server connection fails (3-way handshake failed, refused, timeout) -> ServerMaintenanceException
Future<T> _wrapNetworkCall<T>(Future<T> Function() call) async {
  try {
    final result = await call();
    if (ServerStatusService.instance.isMaintenanceMode.value ||
        ServerStatusService.instance.isNoInternetMode.value) {
      ServerStatusService.instance.setAllOnline();
    }
    return result;
  } on NoInternetException {
    ServerStatusService.instance.setNoInternetMode(true);
    rethrow;
  } on ServerMaintenanceException {
    ServerStatusService.instance.setMaintenanceMode(true);
    rethrow;
  } on ApiException {
    rethrow;
  } on SocketException catch (e) {
    final msg = e.message.toLowerCase();
    final osMsg = e.osError?.message.toLowerCase() ?? '';
    final combined = '$msg $osMsg';

    // 1. Device network is OFF (unreachable, down, failed host lookup, no route)
    if (combined.contains('network is unreachable') ||
        combined.contains('network is down') ||
        combined.contains('no route to host') ||
        combined.contains('failed host lookup')) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    }

    // 2. Check actual device Internet connectivity
    final hasInternet = await checkDeviceInternetConnectivity();
    if (!hasInternet) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    }

    // 3. Device has Internet, but backend server connection failed
    ServerStatusService.instance.setMaintenanceMode(true);
    throw ServerMaintenanceException('Please try again later.');
  } on TimeoutException {
    final hasInternet = await checkDeviceInternetConnectivity();
    if (!hasInternet) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    } else {
      ServerStatusService.instance.setMaintenanceMode(true);
      throw ServerMaintenanceException('Please try again later.');
    }
  } on real_http.ClientException catch (e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('network is unreachable') ||
        msg.contains('network is down') ||
        msg.contains('failed host lookup') ||
        msg.contains('no route to host')) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    }
    final hasInternet = await checkDeviceInternetConnectivity();
    if (!hasInternet) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    } else {
      ServerStatusService.instance.setMaintenanceMode(true);
      throw ServerMaintenanceException('Please try again later.');
    }
  } catch (e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('network is unreachable') ||
        errStr.contains('network is down') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('no route to host')) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    }
    final hasInternet = await checkDeviceInternetConnectivity();
    if (!hasInternet) {
      ServerStatusService.instance.setNoInternetMode(true);
      throw NoInternetException('Please check your internet connection and try again.');
    }
    rethrow;
  }
}

Future<real_http.Response> get(
  Uri url, {
  Map<String, String>? headers,
  Duration timeout = _defaultTimeout,
}) async {
  return _wrapNetworkCall(() async {
    // Add cache buster to bypass aggressive CloudFront error caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = url.query.isNotEmpty ? '&' : (url.toString().contains('?') ? '&' : '?');
    final cacheBuster = '_t=$timestamp';
    final newUrl = Uri.parse('${url.toString()}$separator$cacheBuster');

    final mergedHeaders = Map<String, String>.from(headers ?? {});
    mergedHeaders['Cache-Control'] = 'no-cache';
    mergedHeaders['Pragma'] = 'no-cache';

    final res = await real_http.get(newUrl, headers: mergedHeaders).timeout(timeout);
    return processResponse(res);
  });
}

Future<Object?> _prepareRequestBody(Object? body) async {
  if (body == null) return null;
  if (body is Map) {
    return await TransitCrypto.encryptPayload(body);
  }
  if (body is String && (body.trim().startsWith('{') || body.trim().startsWith('['))) {
    try {
      final decoded = jsonDecode(body);
      final encrypted = await TransitCrypto.encryptPayload(decoded);
      return jsonEncode(encrypted);
    } catch (_) {
      return body;
    }
  }
  return body;
}

Future<Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  return _wrapNetworkCall(() async {
    final finalBody = await _prepareRequestBody(body);
    final res = await real_http
        .post(url, headers: headers, body: finalBody, encoding: encoding)
        .timeout(timeout);
    return processResponse(res);
  });
}

Future<Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  return _wrapNetworkCall(() async {
    final finalBody = await _prepareRequestBody(body);
    final res = await real_http
        .put(url, headers: headers, body: finalBody, encoding: encoding)
        .timeout(timeout);
    return processResponse(res);
  });
}

Future<Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  return _wrapNetworkCall(() async {
    final res = await real_http
        .delete(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
        )
        .timeout(timeout);
    return processResponse(res);
  });
}

Future<Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  return _wrapNetworkCall(() async {
    final finalBody = await _prepareRequestBody(body);
    final res = await real_http
        .patch(
          url,
          headers: headers,
          body: finalBody,
          encoding: encoding,
        )
        .timeout(timeout);
    return processResponse(res);
  });
}
