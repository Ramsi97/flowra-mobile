import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
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
          const SizedBox(width: 12),
          Expanded(child: _buildTaskCard(context)),
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
              color: task.status == 'done'
                  ? AppColors.success
                  : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (task.status == 'done'
                              ? AppColors.success
                              : AppColors.primary)
                          .withOpacity(0.5),
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

  Widget _buildTaskCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskDetailPage(task: task)),
          );
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.duration,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
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
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPriorityColor().withOpacity(0.3),
                  ),
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
