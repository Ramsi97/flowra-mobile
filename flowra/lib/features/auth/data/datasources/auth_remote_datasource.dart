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

    // Save token securely
    final token = body['token'] as String;
    await apiClient.saveToken(token);
    final userJsonStr = json.encode(body['user']);
    await apiClient.saveUser(userJsonStr);
    return body as Map<String, dynamic>;
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
    await apiClient.deleteUser();
  }

  Future<bool> hasToken() async {
    final token = await apiClient.getToken();
    return token != null;
  }

  Future<UserModel?> getUser() async {
    final userJsonStr = await apiClient.getUser();
    if (userJsonStr != null) {
      return UserModel.fromJson(json.decode(userJsonStr) as Map<String, dynamic>);
    }
    return null;
  }
}
