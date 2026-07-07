import '../../domain/entities/schedule_item.dart';

class ScheduleItemModel extends ScheduleItem {
  const ScheduleItemModel({
    required super.id,
    required super.userId,
    required super.taskId,
    required super.title,
    required super.startTime,
    required super.endTime,
    required super.isHard,
    required super.status,
    super.createdAt,
    super.updatedAt,
  });

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      isHard: json['is_hard'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'title': title,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_hard': isHard,
      'status': status,
    };
  }

  static List<ScheduleItemModel> fromJsonList(List<dynamic> list) {
    return list
        .map((e) => ScheduleItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
