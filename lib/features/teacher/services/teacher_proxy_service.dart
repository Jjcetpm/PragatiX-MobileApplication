import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;

class TeacherProxyService {
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.post(url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.put(url, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.delete(url, headers: headers, body: body, encoding: encoding);
  }
}
