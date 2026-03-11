import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<dynamic> get(String path) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }
}
