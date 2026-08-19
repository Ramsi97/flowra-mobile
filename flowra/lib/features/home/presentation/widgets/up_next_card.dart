import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_pills.dart' show priorityLabel;
import '../../../task/domain/entities/task.dart';
import '../../../schedule/domain/entities/schedule_item.dart';

/// The dashboard's hero "what now?" card. Renders one of three states on a
/// gradient surface:
///  * an active focus session ([activeFocusItem] set),
///  * the next task to tackle ([nextTask] set), or
///  * a prompt to plan the day when there is nothing queued.
class UpNextCard extends StatelessWidget {
  final Task? nextTask;
  final ScheduleItem? activeFocusItem;
  final VoidCallback onStartFocus;
  final VoidCallback onPlanDay;

  const UpNextCard({
    super.key,
    this.nextTask,
    this.activeFocusItem,
    required this.onStartFocus,
    required this.onPlanDay,
  });

  ({
    String label,
    IconData icon,
    String title,
    String? subtitle,
    String cta,
    IconData ctaIcon,
    VoidCallback onTap,
  }) _resolve() {
    if (activeFocusItem != null) {
      final item = activeFocusItem!;
      final range =
          '${DateFormat('h:mm a').format(item.startTime)} – ${DateFormat('h:mm a').format(item.endTime)}';
      return (
        label: 'FOCUSING NOW',
        icon: Icons.bolt_rounded,
        title: item.title,
        subtitle: range,
        cta: 'Open Focus',
        ctaIcon: Icons.self_improvement_rounded,
        onTap: onStartFocus,
      );
    }
    if (nextTask != null) {
      final t = nextTask!;
      final bits = <String>[];
      if (t.duration.trim().isNotEmpty) bits.add(t.duration.trim());
      bits.add('${priorityLabel(t.priority)} priority');
      if (t.deadline != null) {
        bits.add('by ${DateFormat('h:mm a').format(t.deadline!)}');
      }
      return (
        label: 'UP NEXT',
        icon: Icons.arrow_forward_rounded,
        title: t.title,
        subtitle: bits.join('   ·   '),
        cta: 'Start Focus',
        ctaIcon: Icons.self_improvement_rounded,
        onTap: onStartFocus,
      );
    }
    return (
      label: 'PLAN YOUR DAY',
      icon: Icons.auto_awesome_rounded,
      title: 'Nothing up next',
      subtitle: 'Let the AI draft a plan for your day.',
      cta: 'Plan my day',
      ctaIcon: Icons.auto_awesome_rounded,
      onTap: onPlanDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolve();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(c.icon,
                    size: 15, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Text(
                  c.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              c.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            if (c.subtitle != null) ...[
              const SizedBox(height: AppDimens.xs),
              Text(
                c.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: AppDimens.lg),
            _CtaButton(label: c.cta, icon: c.ctaIcon, onTap: c.onTap),
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CtaButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.lg, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppColors.primaryDark),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
