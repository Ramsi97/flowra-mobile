import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecase/update_profile_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Handles editing the current user's profile & preferences.
///
/// Kept separate from [AuthBloc] on purpose: the root _AuthGate reacts to
/// AuthBloc states, so routing a profile save through it would risk bouncing
/// the user out of the home surface. This bloc owns its own loading/error
/// lifecycle instead.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;

  ProfileBloc({required this.updateProfileUseCase})
      : super(ProfileInitial()) {
    on<UpdateProfileSubmitted>(_onUpdateSubmitted);
  }

  Future<void> _onUpdateSubmitted(
    UpdateProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileSaving());
    final result = await updateProfileUseCase(
      event.user,
      imagePath: event.imagePath,
    );
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (user) => emit(ProfileSaved(user)),
    );
  }
}
