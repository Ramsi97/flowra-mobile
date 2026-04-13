part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

final class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String gender;
  RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.gender,
  });
}

final class LogoutRequested extends AuthEvent {}
