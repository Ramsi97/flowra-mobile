import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/edit_profile_page.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/theme_event.dart';
import '../bloc/theme_state.dart';

/// Settings, trimmed to the controls that actually do something.
///
/// Sections:
///   • Profile header (tap → Edit Profile)
///   • Appearance    – Light/Dark picker with live theme previews (persisted)
///   • Workday       – live summary of work hours + rest-day chips (→ Edit
///     Profile, the single editor for those fields)
///   • About         – app version / about dialog
///   • Sign Out
///   • Branded footer
///
/// Decorative-only controls that were wired to nothing (accent picker,
/// notification toggles, compact view, app icon, account & support stubs) have
/// been removed rather than left as dead switches.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<String> _dayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  /// Single-letter labels for the rest-day chips (Sun … Sat).
  static const List<String> _dayInitials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final isDark = themeState.themeMode == ThemeMode.dark;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                AppHeader(
                  title: 'Settings',
                  onBack: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.xl,
                    AppDimens.sm,
                    AppDimens.xl,
                    AppDimens.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile header ──────────────────────────────────
                      _buildProfileHeader(context),
                      const SizedBox(height: AppDimens.xxl),

                      // ── Appearance ──────────────────────────────────────
                      _buildSectionLabel(context, 'APPEARANCE'),
                      const SizedBox(height: AppDimens.md),
                      _buildThemePicker(context, isDark),
                      const SizedBox(height: AppDimens.xxl),

                      // ── Workday ─────────────────────────────────────────
                      _buildSectionLabel(context, 'WORKDAY'),
                      const SizedBox(height: AppDimens.md),
                      _buildWorkdayCard(context),
                      const SizedBox(height: AppDimens.xxl),

                      // ── About ───────────────────────────────────────────
                      _buildSectionLabel(context, 'ABOUT'),
                      const SizedBox(height: AppDimens.md),
                      _buildGroupCard(context, [
                        _buildNavTile(
                          context,
                          icon: Icons.info_outline_rounded,
                          iconColor: AppColors.info,
                          title: 'About Flowra',
                          subtitle: 'Version 1.0.0',
                          onTap: () => _showAbout(context),
                        ),
                      ]),
                      const SizedBox(height: AppDimens.xxl),

                      // ── Sign Out ─────────────────────────────────────────
                      _buildSignOutButton(context),
                      const SizedBox(height: AppDimens.xxl),

                      // ── Footer ───────────────────────────────────────────
                      _buildFooter(context),
                      const SizedBox(height: AppDimens.lg),
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

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openEditProfile(BuildContext context, User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: EditProfilePage(user: user),
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.xs),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.getTextMuted(context),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // ── Profile header ────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final hasAvatar = user != null && user.profilePictureUrl.isNotEmpty;
        final initial = (user != null && user.fullName.trim().isNotEmpty)
            ? user.fullName.trim()[0].toUpperCase()
            : '?';

        return GestureDetector(
          onTap: user == null ? null : () => _openEditProfile(context, user),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              child: Stack(
                children: [
                  // Decorative glow circles for depth.
                  Positioned(
                    top: -34,
                    right: -20,
                    child: _decorCircle(130, 0.12),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -24,
                    child: _decorCircle(120, 0.08),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Avatar
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
                                        image:
                                            NetworkImage(user.profilePictureUrl),
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
                            // Name + email
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
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.md),
                        // Edit Profile button
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMd),
                            onTap: user == null
                                ? null
                                : () => _openEditProfile(context, user),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppDimens.sm + 2),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  // ── Theme picker ──────────────────────────────────────────────────────────

  /// Two side-by-side preview cards for Light / Dark. Each renders a small
  /// mockup in its own theme colours (so both previews look right regardless of
  /// the active theme) and drives [SetThemeEvent] on tap.
  Widget _buildThemePicker(BuildContext context, bool isDark) {
    void select(ThemeMode mode) =>
        context.read<ThemeBloc>().add(SetThemeEvent(mode));

    return Row(
      children: [
        Expanded(
          child: _ThemePreviewCard(
            dark: false,
            selected: !isDark,
            onTap: () => select(ThemeMode.light),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: _ThemePreviewCard(
            dark: true,
            selected: isDark,
            onTap: () => select(ThemeMode.dark),
          ),
        ),
      ],
    );
  }

  // ── Workday summary ───────────────────────────────────────────────────────

  Widget _buildWorkdayCard(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavTile(
                  context,
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.primary,
                  title: 'Work hours',
                  subtitle: user == null
                      ? 'Sign in to set your workday'
                      : _hoursSummary(user),
                  onTap: user == null
                      ? null
                      : () => _openEditProfile(context, user),
                ),
                if (user != null) ...[
                  _divider(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.md,
                      AppDimens.md,
                      AppDimens.md,
                      AppDimens.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'REST DAYS',
                              style: TextStyle(
                                color: AppColors.getTextMuted(context),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.9,
                              ),
                            ),
                            Text(
                              _restDaysLabel(user.restDays),
                              style: TextStyle(
                                color: AppColors.getTextSecondary(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.sm + 2),
                        _buildDayChips(context, user.restDays),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// A 7-chip week strip; rest days are highlighted in the brand colour.
  Widget _buildDayChips(BuildContext context, List<int> restDays) {
    final rest = restDays.toSet();
    return Row(
      children: List.generate(7, (i) {
        final isRest = rest.contains(i);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isRest
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(
                  color: isRest
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.getBorder(context),
                ),
              ),
              child: Text(
                _dayInitials[i],
                style: TextStyle(
                  color: isRest
                      ? AppColors.primary
                      : AppColors.getTextMuted(context),
                  fontSize: 12.5,
                  fontWeight: isRest ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Work hours as a 12-hour range, or a hint when unset.
  String _hoursSummary(User user) {
    final start = _displayTime(user.workDayStart);
    final end = _displayTime(user.workDayEnd);
    return (start != null && end != null) ? '$start – $end' : 'Hours not set';
  }

  /// Converts a stored `"HH:mm"` string into a 12-hour label, or null if the
  /// value is empty/malformed. Matches the format written by Edit Profile.
  String? _displayTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  /// Rest-day indices (0 = Sun … 6 = Sat, matching Edit Profile) → short names.
  String _restDaysLabel(List<int> days) {
    final names = (<int>[...days]..sort())
        .where((d) => d >= 0 && d < _dayNames.length)
        .map((d) => _dayNames[d])
        .toList();
    return names.isEmpty ? 'None set' : names.join(', ');
  }

  // ── Grouped card ─────────────────────────────────────────────────────────

  /// A rounded card holding a column of tiles, hairline-divided. The [ClipRRect]
  /// keeps each tile's ink ripple inside the card's rounded corners.
  Widget _buildGroupCard(BuildContext context, List<Widget> children) {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) divided.add(_divider(context));
      divided.add(children[i]);
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: divided,
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: AppDimens.md,
        endIndent: AppDimens.md,
        color: AppColors.getBorder(context),
      );

  // ── Nav tile (arrow) ──────────────────────────────────────────────────────

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.md),
        child: Row(
          children: [
            _iconBadge(icon, iconColor),
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
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.getTextMuted(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Sign Out button ───────────────────────────────────────────────────────

  Widget _buildSignOutButton(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: () {
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md, vertical: AppDimens.md + 2),
          child: Row(
            children: [
              _iconBadge(Icons.logout_rounded, AppColors.error),
              const SizedBox(width: AppDimens.md),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            'Flowra',
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: AppColors.getTextMuted(context),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon badge helper ─────────────────────────────────────────────────────

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 19),
    );
  }

  // ── About dialog ──────────────────────────────────────────────────────────

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Flowra',
      applicationVersion: 'Version 1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
      ),
      children: [
        Text(
          'Your focus & scheduling companion — plan the day, protect your '
          'attention, and keep your flow.',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Theme preview card ────────────────────────────────────────────────────────

/// A tappable card showing a miniature mockup of the light or dark theme, used
/// by the Appearance picker. Renders in fixed theme colours (not the active
/// theme) so both previews always look correct, and lifts with a brand border +
/// glow when selected.
class _ThemePreviewCard extends StatelessWidget {
  final bool dark;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.dark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface =
        dark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    final line = dark ? const Color(0x33FFFFFF) : const Color(0xFFD5D8E2);
    final cardBorder = dark ? const Color(0x22FFFFFF) : AppColors.lightBorder;

    return Material(
      color: AppColors.getSurface(context),
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppDimens.sm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.getBorder(context),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini theme mockup
              Container(
                height: 88,
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _bar(30, 5, line),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bar(28, 4, AppColors.accent),
                            const SizedBox(height: 6),
                            _bar(double.infinity, 4, line),
                            const SizedBox(height: 5),
                            _bar(42, 4, line),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.sm + 2),
              // Label + selected indicator
              Row(
                children: [
                  Icon(
                    dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 16,
                    color: selected
                        ? AppColors.primary
                        : AppColors.getTextSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dark ? 'Dark' : 'Light',
                    style: TextStyle(
                      color: selected
                          ? AppColors.getTextPrimary(context)
                          : AppColors.getTextSecondary(context),
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _selectionDot(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionDot(BuildContext context) {
    if (selected) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.getBorder(context), width: 1.5),
      ),
    );
  }

  Widget _bar(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
