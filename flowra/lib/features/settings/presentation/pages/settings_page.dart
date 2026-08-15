import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/bloc/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/edit_profile_page.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/theme_event.dart';
import '../bloc/theme_state.dart';

/// The account/preferences surface, reachable from the gear button on every
/// tab (see [SettingsButton]). Formerly built inline inside `HomePage` as a
/// hidden 5th tab; now a normal pushed route so any page can open it.
///
/// Reads [ThemeBloc] and [AuthBloc] straight from context — both are provided
/// above `MaterialApp` in `main.dart`, so a pushed route still sees them.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final isDark = state.themeMode == ThemeMode.dark;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                AppHeader(
                  title: 'Settings',
                  onBack: () => Navigator.pop(context),
                ),
                Padding(
                  padding: AppDimens.screenPadding,
                  child: Column(
                    children: [
                      _buildProfileHeader(context),
                      AppDimens.vGapLg,
                      _buildSettingTile(
                        context,
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Dark Mode',
                        subtitle: 'Toggle between dark and light themes',
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) =>
                              context.read<ThemeBloc>().add(ToggleThemeEvent()),
                        ),
                      ),
                      AppDimens.vGapMd,
                      _buildSettingTile(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Log Out',
                        subtitle: 'Sign out of your account',
                        iconColor: AppColors.error,
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: AppColors.getTextMuted(context),
                        ),
                        onTap: () {
                          context.read<AuthBloc>().add(LogoutRequested());
                          // Settings is a pushed route now, so clear it (and any
                          // deeper routes) to let _AuthGate show the LoginPage.
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final hasAvatar = user != null && user.profilePictureUrl.isNotEmpty;
        final initial = (user != null && user.fullName.trim().isNotEmpty)
            ? user.fullName.trim()[0].toUpperCase()
            : '?';

        return GestureDetector(
          onTap: user == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: EditProfilePage(user: user),
                      ),
                    ),
                  ),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.lg),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    image: hasAvatar
                        ? DecorationImage(
                            image: NetworkImage(user.profilePictureUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: hasAvatar
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: AppDimens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName
                            : 'Your Profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'Tap to edit your profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final color = iconColor ?? AppColors.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimens.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          trailing,
        ],
      ),
    );
  }
}
