import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';

class ApiClient {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  ApiClient({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // ── Token helpers ──────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse('${Endpoints.baseUrl}$path');

  Future<dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return Future.value(null);
      return Future.value(json.decode(response.body));
    } else {
      throw Exception('API Error (${response.statusCode}): ${response.body}');
    }
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await _client.get(_uri(path), headers: await _headers(auth: auth));
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: await _headers(auth: auth),
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await _client.delete(
      _uri(path),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  Future<dynamic> postProtected(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(auth: true),
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }
}
