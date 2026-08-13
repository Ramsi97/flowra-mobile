import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Large page header: optional leading (back), a title + optional subtitle, and
/// an optional trailing widget (avatar / menu / action). Replaces the manual
/// header rows built inline on Home, Schedule, Focus and Settings.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(
      AppDimens.xl,
      AppDimens.lg,
      AppDimens.xl,
      AppDimens.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack!),
            AppDimens.gapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[AppDimens.gapMd, trailing!],
        ],
      ),
    );
  }
}

/// Small circular icon button used for header back/actions.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getSurface(context),
      shape: CircleBorder(side: BorderSide(color: AppColors.getBorder(context))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: AppColors.getTextPrimary(context)),
        ),
      ),
    );
  }
}
