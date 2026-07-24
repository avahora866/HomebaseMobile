import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

String get _xInternalHeaderValue => dotenv.env['X_INTERNAL_HEADER'] ?? '';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Internal-Header': _xInternalHeaderValue,
      };

  Uri _buildUri(String endpoint) {
    return Uri.parse('${AppConfig.baseUrl}$endpoint');
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _client.get(_buildUri(endpoint), headers: _headers);
    return _handleResponse(response);
  }

  /// Calls a fully-qualified external URL without prepending [AppConfig.baseUrl]
  /// and without the internal auth header.
  Future<Map<String, dynamic>> getAbsolute(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      _buildUri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final response = await _client.put(
      _buildUri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response =
        await _client.delete(_buildUri(endpoint), headers: _headers);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final bool ok = response.statusCode >= 200 && response.statusCode < 300;

    // Safely decode — body may be empty (e.g. 204 No Content) or
    // non-JSON (e.g. plain text error from Spring).
    dynamic decoded;
    final body = response.body.trim();

    if (body.isEmpty) {
      decoded = null;
    } else {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        // Not valid JSON — treat the raw string as the payload
        decoded = body;
      }
    }

    if (ok) {
      return {'success': true, 'data': decoded, 'status': response.statusCode};
    } else {
      return {
        'success': false,
        'error': decoded ?? 'Unknown error (${response.statusCode})',
        'status': response.statusCode,
      };
    }
  }
}
