import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// A friendly, reusable error state: an icon, a human-readable message and an
/// optional retry action. Replaces raw red error text scattered across pages.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.error, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
