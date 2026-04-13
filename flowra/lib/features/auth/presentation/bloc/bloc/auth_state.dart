part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final User user;
  final String token;
  AuthAuthenticated({required this.user, required this.token});
}

final class AuthUnauthenticated extends AuthState {}

final class AuthRegistered extends AuthState {}

final class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
