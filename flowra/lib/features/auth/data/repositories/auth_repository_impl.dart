import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../model/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, AuthResponse>> login(
    String email,
    String password,
  ) async {
    try {
      final data = await remoteDatasource.login(email, password);
      final userJson = data['user'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(userJson);
      return Right(AuthResponse(token: token, user: user));
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> register(User user, String password) async {
    try {
      final model = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        gender: user.gender,
      );
      await remoteDatasource.register(model, password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDatasource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(
    User user, {
    String? imagePath,
  }) async {
    try {
      final model = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        gender: user.gender,
        profilePictureUrl: user.profilePictureUrl,
        restDays: user.restDays,
        workDayStart: user.workDayStart,
        workDayEnd: user.workDayEnd,
        blockedApps: user.blockedApps,
        focusModeEnabled: user.focusModeEnabled,
        createdAt: user.createdAt,
      );
      final updated =
          await remoteDatasource.updateProfile(model, imagePath: imagePath);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> checkAuth() async {
    try {
      final hasToken = await remoteDatasource.hasToken();
      if (!hasToken) return const Left(ServerFailure('No cached token'));

      // A restorable session must also have a refresh token; without one an
      // expired access token can never be renewed, so treat it as logged out
      // rather than opening the app onto guaranteed 401s.
      final hasRefreshToken = await remoteDatasource.hasRefreshToken();
      if (!hasRefreshToken) return const Left(ServerFailure('No refresh token'));

      final token = await remoteDatasource.apiClient.getToken();
      final user = await remoteDatasource.getUser();
      if (token != null && user != null) {
         return Right(AuthResponse(token: token, user: user));
      }
      return const Left(ServerFailure('Invalid cached session'));
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
