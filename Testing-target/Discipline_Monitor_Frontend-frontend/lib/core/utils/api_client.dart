import 'package:http/http.dart' as real_http;
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'dart:convert';

typedef Response = real_http.Response;

Future<Response> get(Uri url, {Map<String, String>? headers}) async {
  return processResponse(await real_http.get(url, headers: headers));
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
