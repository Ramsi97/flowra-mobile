import 'package:equatable/equatable.dart';

class ScheduleItem extends Equatable {
  final String id;
  final String userId;
  final String taskId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isHard;
  final String status; // "pending" | "done" | "skipped"
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ScheduleItem({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isHard,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  ScheduleItem copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isHard,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isHard: isHard ?? this.isHard,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Duration get duration => endTime.difference(startTime);

  @override
  List<Object?> get props => [
        id,
        userId,
        taskId,
        title,
        startTime,
        endTime,
        isHard,
        status,
        createdAt,
        updatedAt,
      ];
}
