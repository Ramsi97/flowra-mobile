import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 10,
                backgroundColor: AppColors.getSurface(context),
                color: AppColors.secondary,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedTasks / $totalTasks Tasks',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Daily Goal Progress',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

