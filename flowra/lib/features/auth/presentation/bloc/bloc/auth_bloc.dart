import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecase/login_usecase.dart';
import '../../../domain/usecase/register_usecase.dart';
import '../../../domain/usecase/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.email, event.password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResponse) => emit(AuthAuthenticated(
        user: authResponse.user,
        token: authResponse.token,
      )),
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final user = User(
      id: '',
      fullName: event.fullName,
      email: event.email,
      gender: event.gender,
    );
    final result = await registerUseCase(user, event.password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthRegistered()),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
