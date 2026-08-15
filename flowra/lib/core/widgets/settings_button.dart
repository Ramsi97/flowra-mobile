import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Circular gear button that opens the [SettingsPage]. Dropped into the
/// top-right of every tab header so Settings is reachable from anywhere.
///
/// Self-contained (no params): it pushes the route itself, which keeps the
/// tab pages that use it decoupled from `HomePage`. Styling mirrors the header
/// back button in `app_header.dart`.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getSurface(context),
      shape:
          CircleBorder(side: BorderSide(color: AppColors.getBorder(context))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            Icons.settings_rounded,
            size: 20,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ),
    );
  }
}
