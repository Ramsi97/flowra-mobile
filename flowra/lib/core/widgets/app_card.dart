import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// The single surface card used across the app.
///
/// Theme-aware background + hairline border, with a soft shadow in light mode
/// so cards lift off the background without heavy blur. Replaces the old mix of
/// [GlassContainer], raw [Container]s and [Card]s.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.lg),
    this.radius = AppDimens.radiusLg,
    this.onTap,
    this.color,
    this.border,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radiusGeom = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      color: color ?? AppColors.getSurface(context),
      borderRadius: radiusGeom,
      border: border ?? Border.all(color: AppColors.getBorder(context)),
      boxShadow: elevated && !isDark
          ? [
              BoxShadow(
                color: const Color(0xFF12131A).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );

    final content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: radiusGeom,
          child: content,
        ),
      ),
    );
  }
}
