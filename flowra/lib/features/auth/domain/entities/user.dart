import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String gender;
  final String profilePictureUrl;
  final List<int> restDays;
  final String workDayStart;
  final String workDayEnd;
  final List<String> blockedApps;
  final bool focusModeEnabled;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.gender,
    this.profilePictureUrl = '',
    this.restDays = const [],
    this.workDayStart = '',
    this.workDayEnd = '',
    this.blockedApps = const [],
    this.focusModeEnabled = false,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        gender,
        profilePictureUrl,
        restDays,
        workDayStart,
        workDayEnd,
        blockedApps,
        focusModeEnabled,
        createdAt,
      ];
}
