part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileSaving extends ProfileState {}

final class ProfileSaved extends ProfileState {
  final User user;
  ProfileSaved(this.user);
}

final class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
