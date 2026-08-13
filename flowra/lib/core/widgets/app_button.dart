import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum AppButtonVariant { primary, tonal, outline, destructive }

/// The app's one button. Handles the four variants used across the app plus a
/// built-in loading spinner and optional leading icon, so screens stop
/// hand-rolling `ElevatedButton`/`Container` gradients.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.icon,
  });

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.icon,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.icon,
  }) : variant = AppButtonVariant.outline;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.icon,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final gradient =
        variant == AppButtonVariant.primary ? AppColors.primaryGradient : null;

    late final Color bg;
    late final Color fg;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case AppButtonVariant.tonal:
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.getTextPrimary(context);
        border = Border.all(color: AppColors.getBorder(context));
        break;
      case AppButtonVariant.destructive:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
    }

    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled && !loading ? 0.5 : 1,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          border: border,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(fg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: fg),
                    const SizedBox(width: AppDimens.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}
