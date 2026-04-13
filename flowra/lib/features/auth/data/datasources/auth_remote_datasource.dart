import 'dart:convert';
import '../../../../core/constants/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../model/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient apiClient;

  AuthRemoteDatasource(this.apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.post(
      Endpoints.login,
      {'email': email, 'password': password},
    );

    final body = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      // Save token securely
      final token = body['token'] as String;
      await apiClient.saveToken(token);
      return body;
    }

    throw Exception(body['error'] ?? 'Login failed');
  }

  Future<void> register(UserModel user, String password) async {
    final payload = {
      'full_name': user.fullName,
      'email': user.email,
      'password': password,
      'gender': user.gender,
    };

    final response = await apiClient.post(Endpoints.register, payload);

    if (response.statusCode != 201) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    // Best-effort server call; always clear local token.
    try {
      await apiClient.postProtected(Endpoints.logout);
    } catch (_) {}
    await apiClient.deleteToken();
  }

  Future<bool> hasToken() async {
    final token = await apiClient.getToken();
    return token != null;
  }
}
