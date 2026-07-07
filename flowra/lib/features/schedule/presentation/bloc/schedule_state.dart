import 'package:equatable/equatable.dart';
import '../../domain/entities/schedule_item.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();
  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {}

class ScheduleLoading extends ScheduleState {
  final List<ScheduleItem>? preservedItems;
  const ScheduleLoading({this.preservedItems});
  @override
  List<Object?> get props => [preservedItems];
}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleItem> items;
  final DateTime selectedDate;
  const ScheduleLoaded(this.items, {required this.selectedDate});
  @override
  List<Object?> get props => [items, selectedDate];
}

class ScheduleOperationSuccess extends ScheduleState {
  final String message;
  final List<ScheduleItem>? updatedItems;
  const ScheduleOperationSuccess(this.message, {this.updatedItems});
  @override
  List<Object?> get props => [message, updatedItems];
}

class ScheduleError extends ScheduleState {
  final String message;
  final List<ScheduleItem>? preservedItems;
  const ScheduleError(this.message, {this.preservedItems});
  @override
  List<Object?> get props => [message, preservedItems];
}
