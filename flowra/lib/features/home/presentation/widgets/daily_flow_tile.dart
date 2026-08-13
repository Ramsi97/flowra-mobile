import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pills.dart';
import '../../../task/domain/entities/task.dart';
import '../../../task/presentation/pages/task_detail_page.dart';

class DailyFlowTile extends StatelessWidget {
  final Task task;
  final bool isFirst;
  final bool isLast;

  const DailyFlowTile({
    super.key,
    required this.task,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeline(context),
          const SizedBox(width: AppDimens.md),
          Expanded(child: _buildTaskCard(context)),
        ],
      ),
    );
  }

  Color _dotColor() {
    switch (task.status) {
      case 'done':
        return AppColors.success;
      case 'skipped':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildTimeline(BuildContext context) {
    final line = AppColors.getBorder(context);
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          Expanded(
            child: isFirst
                ? const SizedBox()
                : Container(width: 2, color: line),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _dotColor(),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.getBackground(context),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _dotColor().withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLast
                ? const SizedBox()
                : Container(width: 2, color: line),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context) {
    final done = task.status == 'done';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: AppCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskDetailPage(task: task)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (task.duration.trim().isNotEmpty) ...[
                  const SizedBox(width: AppDimens.sm),
                  Text(
                    task.duration,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (task.description.trim().isNotEmpty) ...[
              const SizedBox(height: AppDimens.xs),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AppDimens.md),
            PriorityBadge(priority: task.priority),
          ],
        ),
      ),
    );
  }
}
