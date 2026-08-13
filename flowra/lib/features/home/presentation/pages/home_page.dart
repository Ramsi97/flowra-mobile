import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/bloc/task_state.dart';
import '../../../task/domain/entities/task.dart';
import '../widgets/daily_flow_tile.dart';
import '../widgets/daily_goal_header.dart';
import '../../../task/presentation/pages/create_task_page.dart';
import '../../../settings/presentation/bloc/theme_bloc.dart';
import '../../../settings/presentation/bloc/theme_event.dart';
import '../../../settings/presentation/bloc/theme_state.dart';
import '../../../task/presentation/pages/task_detail_page.dart';
import '../../../auth/presentation/bloc/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/edit_profile_page.dart';
import '../../../task/presentation/widgets/task_list_card.dart';
import '../../../task/presentation/pages/ai_assistant_sheet.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../../focus/presentation/pages/focus_page.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/flowra_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Last known task list + view mode. The shared TaskBloc can pass through
  // states that carry no list (e.g. TaskSuggestionsLoaded from the AI sheet,
  // or a mutation with a null preserved list). Caching the last resolved list
  // lets the builders keep rendering it instead of getting stuck on a spinner
  // or blanking out.
  List<Task>? _lastTasks;
  TaskViewMode _lastMode = TaskViewMode.day;

  /// Resolves the task list + mode to render for the current [state], updating
  /// the cache when the state carries a list. Returns null tasks only when we
  /// have genuinely never loaded a list yet (true first load).
  ({List<Task>? tasks, TaskViewMode mode, bool isMutating}) _resolveTaskView(
      TaskState state) {
    if (state is TasksLoaded) {
      _lastTasks = state.tasks;
      _lastMode = state.viewMode;
      return (tasks: state.tasks, mode: state.viewMode, isMutating: false);
    }
    if (state is TaskLoading && state.preservedTasks != null) {
      _lastTasks = state.preservedTasks;
      _lastMode = state.viewMode;
      return (tasks: state.preservedTasks, mode: state.viewMode, isMutating: true);
    }
    if (state is TaskOperationSuccess && state.preservedTasks != null) {
      _lastTasks = state.preservedTasks;
      _lastMode = state.viewMode;
      return (tasks: state.preservedTasks, mode: state.viewMode, isMutating: true);
    }
    // Any other state: keep showing the last known list if we have one.
    return (tasks: _lastTasks, mode: _lastMode, isMutating: false);
  }

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasksEvent(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              // the _AuthGate at the root will automatically show LoginPage.
            }
          },
        ),
        BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            if (state is TaskOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboard(),
              _buildTaskList(),
              const SchedulePage(),
              const FocusPage(),
              _buildSettings(),
            ],
          ),
        ),
        bottomNavigationBar: _selectedIndex == 4 ? null : _buildBottomNav(),
      ),
    );
  }

  Widget _buildSettings() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final isDark = state.themeMode == ThemeMode.dark;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.xl,
                AppDimens.lg,
                AppDimens.xl,
                AppDimens.md,
              ),
              child: Row(
                children: [
                  _CircleBack(onTap: () => setState(() => _selectedIndex = 0)),
                  const SizedBox(width: AppDimens.md),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppDimens.screenPadding,
              child: Column(
                children: [
                  _buildProfileHeader(),
                  AppDimens.vGapLg,
                  _buildSettingTile(
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
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    iconColor: AppColors.error,
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: AppColors.getTextMuted(context),
                    ),
                    onTap: () =>
                        context.read<AuthBloc>().add(LogoutRequested()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader() {
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

  Widget _buildSettingTile({
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

  Widget _buildDashboard() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskError && _lastTasks == null) {
          return ErrorView(
            message: state.message,
            onRetry: () => context
                .read<TaskBloc>()
                .add(LoadTasksEvent(forceRefresh: true)),
          );
        }

        final resolved = _resolveTaskView(state);
        if (resolved.tasks == null) {
          // True first load — nothing to show yet.
          return const AppLoader(message: 'Loading your flow…');
        }

        final List<Task> resolvedTasks = resolved.tasks!;
        final TaskViewMode resolvedMode = resolved.mode;
        final bool isMutating = resolved.isMutating;

        final now = DateTime.now();
        final filteredTasks = resolvedTasks.where((t) {
          if (t.deadline == null) return true;
          final deadline = t.deadline!;
          final startOfToday = DateTime(now.year, now.month, now.day);

          if (resolvedMode == TaskViewMode.day) {
            return deadline.year == now.year &&
                deadline.month == now.month &&
                deadline.day == now.day;
          } else if (resolvedMode == TaskViewMode.week) {
            final weekFromNow = now.add(const Duration(days: 7));
            return deadline.isBefore(weekFromNow) &&
                !deadline.isBefore(startOfToday);
          }
          return true; // Month/All for now
        }).toList();

        final completedCount =
            filteredTasks.where((t) => t.status == 'done').length;
        final percentage =
            filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;

        final scrollView = CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final user =
                      authState is AuthAuthenticated ? authState.user : null;
                  return FlowraAppBar(
                    avatarUrl: user?.profilePictureUrl,
                    userName: user?.fullName,
                    onProfileTap: () => setState(() => _selectedIndex = 4),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.xl),
                child: DailyGoalHeader(
                  percentage: percentage,
                  completedTasks: completedCount,
                  totalTasks: filteredTasks.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.xl,
                AppDimens.sm,
                AppDimens.xl,
                AppDimens.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Daily Flow',
                  actionLabel: 'View all',
                  onAction: () => setState(() => _selectedIndex = 1),
                ),
              ),
            ),
            if (filteredTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Your day is clear',
                  message:
                      'No tasks scheduled for this view. Add one or ask the AI to plan your day.',
                  primaryLabel: 'Add a task',
                  onPrimary: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateTaskPage()),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return DailyFlowTile(
                        task: filteredTasks[index],
                        isFirst: index == 0,
                        isLast: index == filteredTasks.length - 1,
                      );
                    },
                    childCount: filteredTasks.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );

        // During a mutation, show an overlay spinner so the list stays visible.
        if (isMutating) {
          return Stack(
            children: [
              scrollView,
              const AppLoaderOverlay(),
            ],
          );
        }
        return scrollView;
      },
    );
  }

  Widget _buildTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskError && _lastTasks == null) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<TaskBloc>().add(LoadTasksEvent()),
          );
        }

        final resolved = _resolveTaskView(state);
        final List<Task>? tasks = resolved.tasks;
        final bool isMutating = resolved.isMutating;

        if (tasks == null) {
          // True first load with no data yet.
          return const AppLoader(message: 'Loading tasks…');
        }

        final pendingCount = tasks.where((t) => t.status != 'done').length;

        final listView = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.xl,
                AppDimens.lg,
                AppDimens.xl,
                AppDimens.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tasks',
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$pendingCount pending',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? EmptyState(
                      icon: Icons.checklist_rounded,
                      title: 'No tasks yet',
                      message:
                          'Tap the + button to create your first task, or let the AI assistant draft a plan.',
                      primaryLabel: 'Create a task',
                      onPrimary: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateTaskPage()),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.xl,
                        0,
                        AppDimens.xl,
                        120,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskListCard(
                          task: task,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskDetailPage(task: task),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );

        if (isMutating) {
          return Stack(
            children: [
              listView,
              const AppLoaderOverlay(),
            ],
          );
        }
        return listView;
      },
    );
  }

  Widget _buildBottomNav() {
    // The center action is "add task" on the Tasks tab, else the AI assistant.
    final onTasksTab = _selectedIndex == 1;
    return AppBottomNav(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      centerIcon: onTasksTab ? Icons.add_rounded : Icons.auto_awesome_rounded,
      onCenterTap: () {
        if (onTasksTab) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTaskPage()),
          );
        } else {
          showAiAssistantSheet(context);
        }
      },
      destinations: const [
        AppNavDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
        ),
        AppNavDestination(
          icon: Icons.check_circle_outline_rounded,
          selectedIcon: Icons.check_circle_rounded,
          label: 'Tasks',
        ),
        AppNavDestination(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          label: 'Schedule',
        ),
        AppNavDestination(
          icon: Icons.self_improvement_outlined,
          selectedIcon: Icons.self_improvement_rounded,
          label: 'Focus',
        ),
      ],
    );
  }
}

/// Small circular back button used by the settings pane.
class _CircleBack extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getSurface(context),
      shape:
          CircleBorder(side: BorderSide(color: AppColors.getBorder(context))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ),
    );
  }
}
