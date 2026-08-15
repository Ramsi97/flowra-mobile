import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_picker_sheet.dart';
import '../../../../core/widgets/settings_button.dart';
import '../../domain/entities/focus_status.dart';
import '../bloc/focus_bloc.dart';
import '../bloc/focus_event.dart';
import '../bloc/focus_state.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  /// Bottom clearance so scrolled content never hides behind the floating nav.
  static const double _navClearance = 110;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<FocusBloc>().add(const LoadFocusStatusEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the active-session banner when the app returns to the foreground.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<FocusBloc>().add(const LoadFocusStatusEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.getTextPrimary(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<FocusBloc, FocusState>(
          listener: (context, state) {
            if (state is FocusError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            FocusStatus? status;
            if (state is FocusLoaded) {
              status = state.status;
            } else if (state is FocusLoading) {
              status = state.preserved;
            } else if (state is FocusError) {
              status = state.preserved;
            }

            if (status == null && state is FocusLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (status == null) {
              return _buildRetry();
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<FocusBloc>().add(const LoadFocusStatusEvent()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.xl, AppDimens.lg, AppDimens.xl, _navClearance),
                children: [
                  AppHeader(
                    title: 'Focus',
                    trailing: const SettingsButton(),
                    padding: const EdgeInsets.only(
                        top: AppDimens.sm, bottom: AppDimens.xl),
                  ),
                  _buildStatusCard(status),
                  const SizedBox(height: AppDimens.xxl),
                  _buildFocusToggle(status),
                  const SizedBox(height: AppDimens.xxl),
                  _buildBlockedApps(status, textColor),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRetry() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.getTextMuted(context)),
            const SizedBox(height: AppDimens.lg),
            Text(
              "Couldn't load focus status.",
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: () =>
                  context.read<FocusBloc>().add(const LoadFocusStatusEvent()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(FocusStatus status) {
    final item = status.currentItem;

    if (status.isActive && item != null) {
      final start = DateFormat('h:mm a').format(item.startTime.toLocal());
      final end = DateFormat('h:mm a').format(item.endTime.toLocal());
      return Container(
        padding: const EdgeInsets.all(AppDimens.xxl),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  'IN FOCUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$start – $end',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final bool enabled = status.focusModeEnabled;
    final String title = enabled ? 'No active session' : 'Focus mode is off';
    final String subtitle = enabled
        ? "You're between scheduled blocks. Time to recharge."
        : 'Turn on focus mode to silence distractions during work sessions.';
    final accent = enabled ? AppColors.secondary : AppColors.getTextMuted(context);
    return Container(
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              enabled ? Icons.self_improvement_rounded : Icons.nightlight_round,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimens.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusToggle(FocusStatus status) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: const Color(0xFF12131A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.xl, vertical: AppDimens.sm),
        value: status.focusModeEnabled,
        title: Text(
          'Focus Mode',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Block distracting apps during scheduled work',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 13,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(AppDimens.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: const Icon(Icons.shield_moon_rounded, color: AppColors.primary),
        ),
        onChanged: (v) =>
            context.read<FocusBloc>().add(ToggleFocusModeEvent(v)),
      ),
    );
  }

  Widget _buildBlockedApps(FocusStatus status, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Blocked Apps',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAppPicker(status),
              icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
              label: const Text('Choose'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        if (status.blockedApps.isEmpty)
          GestureDetector(
            onTap: () => _openAppPicker(status),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.xxl, horizontal: AppDimens.lg),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Column(
                children: [
                  Icon(Icons.apps_rounded,
                      color: AppColors.getTextSecondary(context), size: 32),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'No apps blocked yet.\nTap to choose the ones that pull you off task.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: AppDimens.sm,
            runSpacing: AppDimens.sm,
            children: status.blockedApps.map((app) {
              return Chip(
                label: Text(app),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3)),
                labelStyle: TextStyle(color: AppColors.getTextPrimary(context)),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
                deleteIconColor: AppColors.error,
                onDeleted: () =>
                    context.read<FocusBloc>().add(RemoveBlockedAppEvent(app)),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _openAppPicker(FocusStatus status) async {
    final bloc = context.read<FocusBloc>();
    final result = await showAppPickerSheet(
      context,
      selected: status.blockedApps,
    );
    if (result != null) {
      bloc.add(SetBlockedAppsEvent(result));
    }
  }
}
