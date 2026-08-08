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
  if (response.statusCode >= 400 || (response.body.isNotEmpty && response.body.trim().startsWith('<'))) {
    String message = 'An error occurred';
    try {
      if (response.body.trim().startsWith('<')) {
        message = 'Server returned an HTML page (Possible Backend Error or Gateway Timeout)';
      } else {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['error'] ?? message;
      }
    } catch (_) {}
    // If it was a 200 OK with HTML, we treat it as a 500 server error logically.
    final statusCode = response.statusCode < 400 ? 500 : response.statusCode;
    throw ApiException(statusCode, message);
  }
  return response;
}
