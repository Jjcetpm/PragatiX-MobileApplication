import 'package:http/http.dart' as real_http;
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'dart:convert';

typedef Response = real_http.Response;

Future<real_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  // Add cache buster to bypass aggressive CloudFront error caching
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final separator = url.query.isNotEmpty ? '&' : (url.toString().contains('?') ? '&' : '?');
  final cacheBuster = '_t=$timestamp';
  final newUrl = Uri.parse('${url.toString()}$separator$cacheBuster');
  
  final mergedHeaders = Map<String, String>.from(headers ?? {});
  mergedHeaders['Cache-Control'] = 'no-cache';
  mergedHeaders['Pragma'] = 'no-cache';
  
  return processResponse(await real_http.get(newUrl, headers: mergedHeaders));
}

Future<Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  return processResponse(
    await real_http.post(url, headers: headers, body: body, encoding: encoding),
  );
}

Future<Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  return processResponse(
    await real_http.put(url, headers: headers, body: body, encoding: encoding),
  );
}

Future<Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  return processResponse(
    await real_http.delete(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    ),
  );
}
