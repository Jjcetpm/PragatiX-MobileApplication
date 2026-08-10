import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

Future<http.Response> processResponse(http.Response response) async {
  if (response.statusCode >= 400) {
    String message = 'An error occurred';
    try {
      final data = jsonDecode(response.body);
      message = data['message'] ?? data['error'] ?? message;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }
  return response;
}
