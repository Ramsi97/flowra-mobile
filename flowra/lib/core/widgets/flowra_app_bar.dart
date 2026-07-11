import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Branded top bar shared across the app's tabs.
///
/// Renders a gradient "Flowra" wordmark (or a plain title on inner tabs) on the
/// left and an optional circular avatar action on the right that typically
/// opens the profile / settings surface. Designed to sit inside a
/// [SafeArea]/[CustomScrollView] as a normal widget rather than a Scaffold
/// AppBar so it composes with the existing sliver layouts.
class FlowraAppBar extends StatelessWidget {
  /// When null, the branded gradient "Flowra" wordmark is shown.
  final String? title;

  /// URL of the user's avatar; falls back to an initials/icon badge.
  final String? avatarUrl;

  /// User's full name, used to derive an initial when [avatarUrl] is empty.
  final String? userName;

  /// Tapped when the avatar/settings action is pressed.
  final VoidCallback? onProfileTap;

  const FlowraAppBar({
    super.key,
    this.title,
    this.avatarUrl,
    this.userName,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
      child: Row(
        children: [
          Expanded(child: _buildTitle(context)),
          if (onProfileTap != null) _buildAvatar(context),
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

  Widget _buildAvatar(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    final initial = (userName != null && userName!.trim().isNotEmpty)
        ? userName!.trim()[0].toUpperCase()
        : null;

    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasImage ? null : AppColors.primaryGradient,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(avatarUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: hasImage
            ? null
            : (initial != null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 22)),
      ),
    );
  }
}
