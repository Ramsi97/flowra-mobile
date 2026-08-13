import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A single destination in [AppBottomNav].
class AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Modern floating bottom navigation: a rounded surface bar with four
/// destinations (a selected pill highlights the active one) and a raised,
/// gradient center action button. Replaces the notched [BottomAppBar].
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavDestination> destinations;
  final IconData centerIcon;
  final VoidCallback onCenterTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    required this.centerIcon,
    required this.onCenterTap,
  }) : assert(destinations.length == 4);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.lg,
        0,
        AppDimens.lg,
        AppDimens.md + MediaQuery.of(context).padding.bottom * 0,
      ),
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _item(context, 0),
                  _item(context, 1),
                  const SizedBox(width: 64),
                  _item(context, 2),
                  _item(context, 3),
                ],
              ),
            ),
            Positioned(
              top: -6,
              child: _CenterButton(icon: centerIcon, onTap: onCenterTap),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    final selected = currentIndex == index;
    final dest = destinations[index];
    final color = selected ? AppColors.primary : AppColors.getTextMuted(context);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? dest.selectedIcon : dest.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                dest.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CenterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.getBackground(context),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
