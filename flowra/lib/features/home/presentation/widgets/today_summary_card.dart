import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_card.dart';

/// Compact "today at a glance" card: a small completion ring paired with the
/// three numbers that matter most — done, pending and high-priority. Replaces
/// the oversized standalone progress ring that used to float alone at the top.
class TodaySummaryCard extends StatelessWidget {
  final double percentage;
  final int done;
  final int pending;
  final int highPriority;

  const TodaySummaryCard({
    super.key,
    required this.percentage,
    required this.done,
    required this.pending,
    required this.highPriority,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percentage.clamp(0.0, 1.0) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
      child: AppCard(
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: AppColors.getBorder(context),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.lg),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(value: done, label: 'Done', color: AppColors.success),
                  _Stat(
                      value: pending,
                      label: 'Pending',
                      color: AppColors.primary),
                  _Stat(
                      value: highPriority,
                      label: 'High',
                      color: AppColors.error),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
