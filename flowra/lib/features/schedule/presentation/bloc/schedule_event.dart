import 'package:equatable/equatable.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  @override
  List<Object?> get props => [];
}

class LoadScheduleEvent extends ScheduleEvent {
  final String date; // "YYYY-MM-DD"
  const LoadScheduleEvent(this.date);
  @override
  List<Object?> get props => [date];
}

class RegenerateScheduleEvent extends ScheduleEvent {
  final String date;
  const RegenerateScheduleEvent(this.date);
  @override
  List<Object?> get props => [date];
}

class UpdateScheduleItemEvent extends ScheduleEvent {
  final String itemId;
  final Map<String, dynamic> updates;
  const UpdateScheduleItemEvent(this.itemId, this.updates);
  @override
  List<Object?> get props => [itemId, updates];
}

class DeleteScheduleItemEvent extends ScheduleEvent {
  final String itemId;
  const DeleteScheduleItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class ClearDayEvent extends ScheduleEvent {
  final String date;
  const ClearDayEvent(this.date);
  @override
  List<Object?> get props => [date];
}

class ClearWeekEvent extends ScheduleEvent {
  final String startDate; // "YYYY-MM-DD" (Monday of the target week)
  const ClearWeekEvent(this.startDate);
  @override
  List<Object?> get props => [startDate];
}

class ClearMonthEvent extends ScheduleEvent {
  final String month; // "YYYY-MM"
  const ClearMonthEvent(this.month);
  @override
  List<Object?> get props => [month];
}

class FixScheduleEvent extends ScheduleEvent {
  final String currentTime;
  const FixScheduleEvent(this.currentTime);
  @override
  List<Object?> get props => [currentTime];
}

class AIScheduleEvent extends ScheduleEvent {
  final String date;
  final String prompt;
  const AIScheduleEvent(this.date, this.prompt);
  @override
  List<Object?> get props => [date, prompt];
}

class ChangeDateEvent extends ScheduleEvent {
  final DateTime date;
  const ChangeDateEvent(this.date);
  @override
  List<Object?> get props => [date];
}
