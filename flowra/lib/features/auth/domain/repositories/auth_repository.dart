import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login(String email, String password);
  Future<Either<Failure, void>> register(User user, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthResponse>> checkAuth();

  /// Updates the current user's profile / preferences. [imagePath], when
  /// non-null, points to a locally-picked avatar to upload. Returns the updated
  /// [User] (as persisted locally).
  Future<Either<Failure, User>> updateProfile(User user, {String? imagePath});
}
