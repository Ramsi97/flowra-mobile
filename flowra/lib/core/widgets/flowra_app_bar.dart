import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Branded top bar for the Home dashboard.
///
/// Renders a gradient "Flowra" wordmark (or a plain title on inner tabs) on the
/// left and an optional [trailing] action on the right (typically a
/// [SettingsButton]). Designed to sit inside a [SafeArea]/[CustomScrollView] as
/// a normal widget rather than a Scaffold AppBar so it composes with the
/// existing sliver layouts.
class FlowraAppBar extends StatelessWidget {
  /// When null, the branded gradient "Flowra" wordmark is shown.
  final String? title;

  /// Optional action rendered at the trailing edge (e.g. the settings gear).
  final Widget? trailing;

  const FlowraAppBar({
    super.key,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
      child: Row(
        children: [
          Expanded(child: _buildTitle(context)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (title != null) {
      return Text(
        title!,
        style: TextStyle(
          color: AppColors.getTextPrimary(context),
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppColors.primaryGradient.createShader(bounds),
      child: const Text(
        'Flowra',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
