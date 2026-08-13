import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Priority label for a task priority int (1 = High … 3 = Low).
String priorityLabel(int priority) {
  switch (priority) {
    case 1:
      return 'High';
    case 2:
      return 'Medium';
    default:
      return 'Low';
  }
}

/// A small filled pill showing a task's priority with its colour.
class PriorityBadge extends StatelessWidget {
  final int priority;
  final bool compact;

  const PriorityBadge({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(priority);
    return _Pill(
      color: color,
      icon: Icons.flag_rounded,
      label: compact ? priorityLabel(priority) : '${priorityLabel(priority)} priority',
    );
  }
}

/// A pill reflecting a task's status ('todo' / 'done' / 'skipped').
class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String label;
    switch (status) {
      case 'done':
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Done';
        break;
      case 'skipped':
        color = AppColors.getTextMuted(context);
        icon = Icons.remove_circle_rounded;
        label = 'Skipped';
        break;
      default:
        color = AppColors.info;
        icon = Icons.radio_button_unchecked_rounded;
        label = 'To do';
    }
    return _Pill(color: color, icon: icon, label: label);
  }
}

/// A neutral, tinted informational chip (duration, deadline, category …).
class AppChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const AppChip({super.key, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.getTextSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _Pill({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
