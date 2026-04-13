import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../task/domain/entities/task.dart';

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
          const SizedBox(width: 12),
          Expanded(child: _buildTaskCard()),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Column(
        children: [
          if (!isFirst)
            Expanded(
              child: Container(
                width: 2,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: task.status == 'done' ? AppColors.success : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (task.status == 'done' ? AppColors.success : AppColors.primary).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  task.duration,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getPriorityColor().withOpacity(0.3)),
              ),
              child: Text(
                _getPriorityLabel(),
                style: TextStyle(
                  color: _getPriorityColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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
        return 'HIGH PRIORITY';
      case 2:
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }
}
