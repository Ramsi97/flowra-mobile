import '../../../schedule/data/model/schedule_item_model.dart';
import '../../domain/entities/focus_status.dart';

class FocusStatusModel extends FocusStatus {
  const FocusStatusModel({
    required super.isActive,
    super.currentItem,
    super.blockedApps,
    super.focusModeEnabled,
  });

  factory FocusStatusModel.fromJson(Map<String, dynamic> json) {
    final rawItem = json['current_item'];
    return FocusStatusModel(
      isActive: json['is_active'] as bool? ?? false,
      currentItem: rawItem is Map<String, dynamic>
          ? ScheduleItemModel.fromJson(rawItem)
          : null,
      blockedApps: (json['blocked_apps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      // The backend only reports active-state; treat an active session as
      // focus-mode-on so the UI reflects reality on first load.
      focusModeEnabled: json['is_active'] as bool? ?? false,
    );
  }
}
