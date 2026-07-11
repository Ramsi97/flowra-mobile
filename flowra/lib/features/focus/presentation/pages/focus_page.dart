import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_picker_sheet.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 8),
                    child: Text(
                      'Focus',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusCard(status),
                  const SizedBox(height: 24),
                  _buildFocusToggle(status),
                  const SizedBox(height: 24),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text("Couldn't load focus status."),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<FocusBloc>().add(const LoadFocusStatusEvent()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(FocusStatus status) {
    final item = status.currentItem;

    if (status.isActive && item != null) {
      final start = DateFormat('h:mm a').format(item.startTime.toLocal());
      final end = DateFormat('h:mm a').format(item.endTime.toLocal());
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
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
                Icon(Icons.bolt, color: Colors.white, size: 20),
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
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 16),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (enabled ? AppColors.secondary : AppColors.textSecondary)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              enabled ? Icons.self_improvement : Icons.nightlight_round,
              color: enabled ? AppColors.secondary : AppColors.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
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
                    height: 1.3,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        value: status.focusModeEnabled,
        activeColor: AppColors.secondary,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_moon, color: AppColors.primary),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAppPicker(status),
              icon: const Icon(Icons.playlist_add_check, size: 18),
              label: const Text('Choose'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (status.blockedApps.isEmpty)
          GestureDetector(
            onTap: () => _openAppPicker(status),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.apps,
                      color: AppColors.getTextSecondary(context), size: 32),
                  const SizedBox(height: 8),
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
            spacing: 8,
            runSpacing: 8,
            children: status.blockedApps.map((app) {
              return Chip(
                label: Text(app),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                labelStyle: TextStyle(color: AppColors.getTextPrimary(context)),
                deleteIcon: const Icon(Icons.close, size: 18),
                deleteIconColor: AppColors.error,
                onDeleted: () => context
                    .read<FocusBloc>()
                    .add(RemoveBlockedAppEvent(app)),
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
