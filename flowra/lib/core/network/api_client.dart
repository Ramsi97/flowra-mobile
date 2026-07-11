import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';

class ApiClient {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const Duration _timeout = Duration(seconds: 15);

  ApiClient({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── Token helpers ──────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return _storage.read(key: _userKey);
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
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
      String errorMessage = 'An error occurred (${response.statusCode})';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('error')) {
            errorMessage = decoded['error'].toString();
          } else if (decoded.containsKey('message')) {
            errorMessage = decoded['message'].toString();
          } else if (response.body.isNotEmpty && response.body.length < 100) {
            errorMessage = response.body; 
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty && response.body.length < 100) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<dynamic> _wrapRequest(Future<http.Response> Function() requestFunc) async {
    try {
      final response = await requestFunc().timeout(
        _timeout,
        onTimeout: () => throw Exception('Connection timeout. Server is not responding.'),
      );
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw Exception('No internet connection or server is unreachable.');
    }
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    return _wrapRequest(
      () async => _client.get(_uri(path), headers: await _headers(auth: auth)),
    );
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true, // default to true so protected endpoints always send token
  }) async {
    return _wrapRequest(
      () async => _client.post(
        _uri(path),
        headers: await _headers(auth: auth),
        body: json.encode(body),
      ),
    );
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _wrapRequest(
      () async => _client.put(
        _uri(path),
        headers: await _headers(auth: auth),
        body: json.encode(body),
      ),
    );
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _wrapRequest(
      () async => _client.delete(
        _uri(path),
        headers: await _headers(auth: auth),
      ),
    );
  }

  Future<dynamic> postProtected(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _wrapRequest(
      () async => _client.post(
        _uri(path),
        headers: await _headers(auth: true),
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  /// Sends a multipart/form-data request, used for endpoints that may include a
  /// file upload (e.g. the profile picture). [fields] values are stringified;
  /// list values are sent as repeated fields so the Go backend's form binding
  /// receives a slice. [filePath], when provided, is attached under
  /// [fileField].
  Future<dynamic> multipart(
    String path, {
    String method = 'PUT',
    Map<String, dynamic> fields = const {},
    String? filePath,
    String fileField = 'profile_picture',
    bool auth = true,
  }) async {
    return _wrapRequest(() async {
      final request = http.MultipartRequest(method, _uri(path));

      final headers = await _headers(auth: auth);
      // Let MultipartRequest set its own multipart Content-Type/boundary.
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      fields.forEach((key, value) {
        if (value == null) return;
        if (value is Iterable) {
          for (final item in value) {
            request.files.add(http.MultipartFile.fromString(key, '$item'));
          }
        } else {
          request.fields[key] = '$value';
        }
      });

      if (filePath != null && filePath.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath(fileField, filePath));
      }

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    });
  }
}
