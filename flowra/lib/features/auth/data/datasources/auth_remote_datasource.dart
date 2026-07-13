import 'dart:convert';
import '../../../../core/constants/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../model/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient apiClient;

  AuthRemoteDatasource(this.apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final body = await apiClient.post(
      Endpoints.login,
      {'email': email, 'password': password},
      auth: false, // no token yet during login
    );

    // Save tokens securely
    final token = body['token'] as String;
    await apiClient.saveToken(token);
    final refreshToken = body['refresh_token'] as String?;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await apiClient.saveRefreshToken(refreshToken);
    }
    final userJsonStr = json.encode(body['user']);
    await apiClient.saveUser(userJsonStr);
    return body as Map<String, dynamic>;
  }

  /// Updates the profile via PUT /auth/profile (multipart so an optional
  /// avatar can be uploaded). Persists the merged user locally and returns it.
  Future<UserModel> updateProfile(UserModel user, {String? imagePath}) async {
    final fields = <String, dynamic>{
      'full_name': user.fullName,
      'email': user.email,
      'gender': user.gender,
      'work_day_start': user.workDayStart,
      'work_day_end': user.workDayEnd,
      'rest_days': user.restDays.map((e) => e.toString()).toList(),
      'blocked_apps': user.blockedApps,
      'focus_mode_enabled': user.focusModeEnabled.toString(),
    };

    await apiClient.multipart(
      Endpoints.updateProfile,
      method: 'PUT',
      fields: fields,
      filePath: imagePath,
    );

    // The endpoint returns only a success message, so persist the model we sent
    // (server-side avatar URL, if any, is refreshed on next login/checkAuth).
    // toJson() omits the id, so re-add it to keep the cached session intact.
    final persisted = user.toJson()..['id'] = user.id;
    await apiClient.saveUser(json.encode(persisted));
    return user;
  }

  Future<void> register(UserModel user, String password) async {
    final payload = {
      'full_name': user.fullName,
      'email': user.email,
      'password': password,
      'gender': user.gender,
    };

    await apiClient.post(Endpoints.register, payload, auth: false); // no token yet during registration
  }

  Future<void> logout() async {
    // Best-effort server call; always clear local token.
    try {
      await apiClient.postProtected(Endpoints.logout);
    } catch (_) {}
    await apiClient.deleteToken();
    await apiClient.deleteRefreshToken();
    await apiClient.deleteUser();
  }

  Future<bool> hasToken() async {
    final token = await apiClient.getToken();
    return token != null;
  }

  Future<bool> hasRefreshToken() async {
    final token = await apiClient.getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getUser() async {
    final userJsonStr = await apiClient.getUser();
    if (userJsonStr != null) {
      return UserModel.fromJson(json.decode(userJsonStr) as Map<String, dynamic>);
    }
    return null;
  }
}
