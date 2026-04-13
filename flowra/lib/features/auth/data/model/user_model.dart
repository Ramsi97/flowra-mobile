import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.gender,
    super.profilePictureUrl,
    super.restDays,
    super.workDayStart,
    super.workDayEnd,
    super.blockedApps,
    super.focusModeEnabled,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      profilePictureUrl: json['profile_picture_url'] as String? ?? '',
      restDays: (json['rest_days'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      workDayStart: json['work_day_start'] as String? ?? '',
      workDayEnd: json['work_day_end'] as String? ?? '',
      blockedApps: (json['blocked_apps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      focusModeEnabled: json['focus_mode_enabled'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'gender': gender,
      'profile_picture_url': profilePictureUrl,
      'rest_days': restDays,
      'work_day_start': workDayStart,
      'work_day_end': workDayEnd,
      'blocked_apps': blockedApps,
      'focus_mode_enabled': focusModeEnabled,
    };
  }
}
