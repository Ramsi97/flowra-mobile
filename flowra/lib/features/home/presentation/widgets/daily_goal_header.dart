import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Hero progress ring on the dashboard showing the share of today's tasks
/// completed. A gradient arc over a soft track with the percentage and a
/// count beneath.
class DailyGoalHeader extends StatelessWidget {
  final double percentage;
  final int completedTasks;
  final int totalTasks;

  const DailyGoalHeader({
    super.key,
    required this.percentage,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percentage.clamp(0.0, 1.0) * 100).round();
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 148,
              height: 148,
              child: CircularProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: AppColors.getBorder(context),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  '$completedTasks of $totalTasks done',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
