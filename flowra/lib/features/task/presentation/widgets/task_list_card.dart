import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../task/domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

class TaskListCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskListCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    String priorityText;
    
    if (task.priority == 1) {
      priorityColor = Colors.red.withOpacity(0.15);
      priorityText = 'high';
    } else if (task.priority == 2) {
      priorityColor = Colors.orange.withOpacity(0.15);
      priorityText = 'medium';
    } else {
      priorityColor = Colors.green.withOpacity(0.15);
      priorityText = 'low';
    }

    return Card(
      color: AppColors.getSurface(context),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white12 
              : Colors.black12,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Indicator
              Padding(
                padding: const EdgeInsets.only(top: 2.0, right: 12.0),
                child: Icon(
                  Icons.drag_indicator,
                  color: AppColors.getTextSecondary(context).withOpacity(0.4),
                  size: 20,
                ),
              ),
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: task.status == 'done',
                    onChanged: (bool? value) {
                      final newStatus = (value == true) ? 'done' : 'todo';
                      context.read<TaskBloc>().add(
                            UpdateTaskEvent(task.id, {'status': newStatus}),
                          );
                    },
                    activeColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(
                      color: AppColors.getTextSecondary(context).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.getTextSecondary(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Development', // Default placeholder to match image
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context).withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            priorityText,
                            style: TextStyle(
                              color: task.priority == 1 ? Colors.redAccent : 
                                     task.priority == 2 ? Colors.orangeAccent : 
                                     Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
