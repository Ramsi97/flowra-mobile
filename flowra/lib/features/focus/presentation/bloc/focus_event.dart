import 'package:equatable/equatable.dart';

abstract class FocusEvent extends Equatable {
  const FocusEvent();
  @override
  List<Object?> get props => [];
}

class LoadFocusStatusEvent extends FocusEvent {
  const LoadFocusStatusEvent();
}

class ToggleFocusModeEvent extends FocusEvent {
  final bool enabled;
  const ToggleFocusModeEvent(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class AddBlockedAppEvent extends FocusEvent {
  final String app;
  const AddBlockedAppEvent(this.app);
  @override
  List<Object?> get props => [app];
}

class RemoveBlockedAppEvent extends FocusEvent {
  final String app;
  const RemoveBlockedAppEvent(this.app);
  @override
  List<Object?> get props => [app];
}

/// Replaces the entire blocked-apps list in one shot (used by the app picker).
class SetBlockedAppsEvent extends FocusEvent {
  final List<String> apps;
  const SetBlockedAppsEvent(this.apps);
  @override
  List<Object?> get props => [apps];
}
