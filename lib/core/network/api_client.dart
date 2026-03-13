import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;

  ApiException({
    required this.statusCode,
    required this.message,
    this.responseBody,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    _checkStatusCode(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<dynamic> get(String path) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
    );
    _checkStatusCode(response);
    return jsonDecode(response.body);
  }

  void _checkStatusCode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(
      statusCode: response.statusCode,
      message: 'HTTP ${response.statusCode} error on ${response.request?.url}',
      responseBody: response.body,
    );
  }
}
