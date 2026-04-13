import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.duration,
    required super.priority,
    required super.isHard,
    required super.status,
    super.deadline,
    super.createdAt,
    super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String? ?? '30m',
      priority: json['priority'] as int? ?? 3,
      isHard: json['is_hard'] as bool? ?? false,
      status: json['status'] as String? ?? 'todo',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
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
      'title': title,
      'description': description,
      'duration': duration,
      'priority': priority,
      'is_hard': isHard,
      'status': status,
      'deadline': deadline?.toIso8601String(),
    };
  }

  static List<TaskModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
