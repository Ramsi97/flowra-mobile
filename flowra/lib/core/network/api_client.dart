import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';

/// Thrown when the session can no longer be recovered (refresh failed or no
/// refresh token). Callers surface this as a "please log in again" state; the
/// [ApiClient.onSessionExpired] callback is also invoked so the app can bounce
/// to the login page globally.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Session expired. Please log in again.']);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userKey = 'auth_user';
  static const Duration _timeout = Duration(seconds: 15);

  /// Invoked once when the session is no longer recoverable (refresh failed).
  /// Wired at app startup to dispatch a logout/redirect to the login page.
  void Function()? onSessionExpired;

  /// De-dupes concurrent refresh attempts: if several requests get a 401 at the
  /// same time, they all await this single in-flight refresh.
  Future<bool>? _refreshInFlight;

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

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
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

  Future<dynamic> _wrapRequest(
    Future<http.Response> Function() requestFunc, {
    bool attemptRefresh = true,
  }) async {
    try {
      var response = await _send(requestFunc);

      // Access token expired/invalid: transparently refresh once and retry.
      if (response.statusCode == 401 && attemptRefresh) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          response = await _send(requestFunc);
        }
        // Still unauthorized → the session is unrecoverable. Clear it and let
        // the app route back to login instead of leaving a dead screen.
        if (response.statusCode == 401) {
          await _clearSession();
          onSessionExpired?.call();
          throw SessionExpiredException();
        }
      }

      return _handleResponse(response);
    } on SocketException catch (_) {
      throw Exception('No internet connection or server is unreachable.');
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() requestFunc) {
    return requestFunc().timeout(
      _timeout,
      onTimeout: () => throw Exception('Connection timeout. Server is not responding.'),
    );
  }

  /// Attempts to mint a fresh access token from the stored refresh token.
  /// Concurrent callers share a single in-flight refresh. Returns whether a new
  /// access token was obtained and persisted.
  Future<bool> _refreshToken() {
    return _refreshInFlight ??=
        _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _client
          .post(
            _uri(Endpoints.refresh),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) return false;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return false;

      final newToken = decoded['token'] as String?;
      if (newToken == null || newToken.isEmpty) return false;

      await saveToken(newToken);
      final newRefresh = decoded['refresh_token'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await saveRefreshToken(newRefresh);
      }
      if (decoded['user'] != null) {
        await saveUser(json.encode(decoded['user']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearSession() async {
    await deleteToken();
    await deleteRefreshToken();
    await deleteUser();
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    return _wrapRequest(
      () async => _client.get(_uri(path), headers: await _headers(auth: auth)),
      attemptRefresh: auth,
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
      attemptRefresh: auth,
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
      attemptRefresh: auth,
    );
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _wrapRequest(
      () async => _client.delete(
        _uri(path),
        headers: await _headers(auth: auth),
      ),
      attemptRefresh: auth,
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
    }, attemptRefresh: auth);
  }
}
