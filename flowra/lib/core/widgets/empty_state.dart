import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_button.dart';

/// Friendly empty state: a soft icon bubble, a title, a supporting line, and up
/// to two CTAs. Used by the dashboard, task list, schedule and focus screens so
/// "nothing here yet" always looks intentional.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.primaryLabel,
    this.onPrimary,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.secondary.withValues(alpha: 0.14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            AppDimens.vGapLg,
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              AppDimens.vGapSm,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
            if (primaryLabel != null) ...[
              AppDimens.vGapXl,
              AppButton(
                label: primaryLabel!,
                onPressed: onPrimary,
                loading: primaryLoading,
                expand: false,
              ),
            ],
            if (secondaryLabel != null) ...[
              AppDimens.vGapSm,
              AppButton.outline(
                label: secondaryLabel!,
                onPressed: onSecondary,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
