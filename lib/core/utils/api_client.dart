import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as real_http;
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'dart:convert';

typedef Response = real_http.Response;
typedef MultipartRequest = real_http.MultipartRequest;
typedef MultipartFile = real_http.MultipartFile;

const Duration _defaultTimeout = Duration(seconds: 25);

Future<void> _checkNetworkReachability() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
    ).timeout(const Duration(milliseconds: 1500));
    if (interfaces.isEmpty) {
      throw const SocketException('Network is unreachable');
    }
  } on SocketException {
    rethrow;
  } catch (_) {
    // If interface listing is not permitted or unsupported, proceed to HTTP request with timeout
  }
}

Future<real_http.Response> get(
  Uri url, {
  Map<String, String>? headers,
  Duration timeout = _defaultTimeout,
}) async {
  await _checkNetworkReachability();
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
}

Future<Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  await _checkNetworkReachability();
  final res = await real_http
      .post(url, headers: headers, body: body, encoding: encoding)
      .timeout(timeout);
  return processResponse(res);
}

Future<Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  await _checkNetworkReachability();
  final res = await real_http
      .put(url, headers: headers, body: body, encoding: encoding)
      .timeout(timeout);
  return processResponse(res);
}

Future<Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Duration timeout = _defaultTimeout,
}) async {
  await _checkNetworkReachability();
  final res = await real_http
      .delete(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      )
      .timeout(timeout);
  return processResponse(res);
}
