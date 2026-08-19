import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// Row of four primary entry points on the dashboard, surfacing the app's core
/// actions (create a task, ask the AI to plan, jump to Focus or Schedule) that
/// were previously buried behind tabs.
class QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onPlanAi;
  final VoidCallback onFocus;
  final VoidCallback onSchedule;

  const QuickActionsRow({
    super.key,
    required this.onAddTask,
    required this.onPlanAi,
    required this.onFocus,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
      child: Row(
        children: [
          Expanded(
            child: _Action(
              icon: Icons.add_rounded,
              label: 'Add task',
              color: AppColors.primary,
              onTap: onAddTask,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: _Action(
              icon: Icons.auto_awesome_rounded,
              label: 'Plan',
              color: AppColors.accent,
              onTap: onPlanAi,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: _Action(
              icon: Icons.self_improvement_rounded,
              label: 'Focus',
              color: AppColors.secondary,
              onTap: onFocus,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: _Action(
              icon: Icons.calendar_month_rounded,
              label: 'Schedule',
              color: AppColors.info,
              onTap: onSchedule,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getSurface(context),
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
