import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskDetailPage extends StatelessWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else if (state is TaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        appBar: AppBar(
          title: const Text('Task Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () {
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildInfoRow(context, 'DURATION', task.duration, Icons.timer),
              const SizedBox(height: 16),
              _buildInfoRow(context, 'PRIORITY', _getPriorityLabel(), Icons.flag,
                  color: _getPriorityColor()),
              const SizedBox(height: 16),
              if (task.deadline != null)
                _buildInfoRow(
                    context,
                    'DEADLINE',
                    _formatDate(task.deadline!),
                    Icons.calendar_today),
              const SizedBox(height: 16),
              _buildInfoRow(context, 'DEEP WORK', task.isHard ? 'Yes' : 'No',
                  Icons.psychology),
              const SizedBox(height: 32),
              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  task.description.isEmpty ? 'No description provided.' : task.description,
                  style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 48),
              BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  final isLoading = state is TaskLoading;
                  final isDone = task.status == 'done';
                  
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final newStatus = isDone ? 'todo' : 'done';
                              context.read<TaskBloc>().add(
                                  UpdateTaskEvent(task.id, {'status': newStatus}));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDone ? AppColors.getSurface(context) : AppColors.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isDone ? 'Mark as Todo' : 'Mark as Done',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: isDone ? AppColors.getTextPrimary(context) : Colors.white),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: task.status == 'done'
                ? AppColors.success.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.status.toUpperCase(),
            style: TextStyle(
              color: task.status == 'done' ? AppColors.success : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          task.title,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getSurface(context),
          title: Text('Delete Task', style: TextStyle(color: AppColors.getTextPrimary(context))),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
              },
            ),
          ],
        );
      },
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day}, ${date.year} $hour:$min $amPm';
  }
}
