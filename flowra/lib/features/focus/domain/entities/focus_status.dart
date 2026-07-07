import 'package:equatable/equatable.dart';
import '../../../schedule/domain/entities/schedule_item.dart';

/// Mirror of the backend `FocusStatus` returned by GET /focus/status.
class FocusStatus extends Equatable {
  /// True when focus mode is enabled AND the user is inside a scheduled block.
  final bool isActive;

  /// The schedule item the user is currently in, if any.
  final ScheduleItem? currentItem;

  /// App identifiers the user chose to block while focusing.
  final List<String> blockedApps;

  /// Global toggle for focus mode. The backend does not echo this in the
  /// status payload, so it is tracked locally from the last known config and
  /// defaults to whether focus is active.
  final bool focusModeEnabled;

  const FocusStatus({
    required this.isActive,
    this.currentItem,
    this.blockedApps = const [],
    this.focusModeEnabled = false,
  });

  FocusStatus copyWith({
    bool? isActive,
    ScheduleItem? currentItem,
    List<String>? blockedApps,
    bool? focusModeEnabled,
  }) {
    return FocusStatus(
      isActive: isActive ?? this.isActive,
      currentItem: currentItem ?? this.currentItem,
      blockedApps: blockedApps ?? this.blockedApps,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
    );
  }

  @override
  List<Object?> get props => [isActive, currentItem, blockedApps, focusModeEnabled];
}
