part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

class UpdateProfileSubmitted extends ProfileEvent {
  final User user;
  final String? imagePath;

  UpdateProfileSubmitted(this.user, {this.imagePath});
}
