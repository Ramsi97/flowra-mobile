import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String duration; // e.g., "60m", "1h30m"
  final int priority; // 1 = High, 3 = Low
  final bool isHard;
  final String status; // "todo", "done", "skipped"
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.duration,
    required this.priority,
    required this.isHard,
    required this.status,
    this.deadline,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        duration,
        priority,
        isHard,
        status,
        deadline,
        createdAt,
        updatedAt,
      ];
}
