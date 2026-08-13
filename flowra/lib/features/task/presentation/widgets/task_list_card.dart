import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pills.dart';
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
    final done = task.status == 'done';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: done,
                onChanged: (bool? value) {
                  final newStatus = (value == true) ? 'done' : 'todo';
                  context.read<TaskBloc>().add(
                        UpdateTaskEvent(task.id, {'status': newStatus}),
                      );
                },
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                side: BorderSide(
                  color: AppColors.getTextMuted(context),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: done
                          ? AppColors.getTextMuted(context)
                          : AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.getTextMuted(context),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      PriorityBadge(priority: task.priority, compact: true),
                      if (task.duration.trim().isNotEmpty)
                        AppChip(
                          icon: Icons.timer_outlined,
                          label: task.duration,
                        ),
                      if (task.deadline != null)
                        AppChip(
                          icon: Icons.event_outlined,
                          label: _formatDeadline(task.deadline!),
                        ),
                      if (task.isHard)
                        const AppChip(
                          icon: Icons.bolt_rounded,
                          label: 'Deep work',
                          color: AppColors.accent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeadline(DateTime d) {
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    if (isToday) return 'Today ${DateFormat('HH:mm').format(d)}';
    if (d.year == now.year) return DateFormat('MMM d').format(d);
    return DateFormat('MMM d, y').format(d);
  }
}
