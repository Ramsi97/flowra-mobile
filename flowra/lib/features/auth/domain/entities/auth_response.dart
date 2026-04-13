import 'user.dart';

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});
}
