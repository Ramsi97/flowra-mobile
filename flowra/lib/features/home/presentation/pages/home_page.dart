import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: SafeArea(
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _fabForIndex(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
  
  Widget _buildSettings() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final isDark = state.themeMode == ThemeMode.dark;
        final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => setState(() => _selectedIndex = 0),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildProfileHeader(textColor),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              title: 'Dark Mode',
              subtitle: 'Toggle between dark and light themes',
              trailing: Switch(
                value: isDark,
                onChanged: (_) => context.read<ThemeBloc>().add(ToggleThemeEvent()),
                activeColor: AppColors.secondary,
              ),
              textColor: textColor,
            ),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out of your account',
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
              ),
              textColor: AppColors.error,
              onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(Color textColor) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final hasAvatar =
            user != null && user.profilePictureUrl.isNotEmpty;
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white54, width: 1.5),
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
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
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
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
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
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkSurface 
            : Colors.white,
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }


  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskPage())),
      backgroundColor: AppColors.secondary,
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }

  Widget _buildDashboard() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        // During a mutation (create/update/delete), TaskLoading carries the
        // preserved list so we can keep the dashboard visible.
        if (state is TaskLoading && state.preservedTasks == null) {
          // Initial load — nothing to show yet.
          return const AppLoader(message: 'Loading your flow…');
        }

        // Resolve the task list from whichever state has one.
        final List<Task> resolvedTasks;
        final TaskViewMode resolvedMode;
        final bool isMutating;

        if (state is TasksLoaded) {
          resolvedTasks = state.tasks;
          resolvedMode = state.viewMode;
          isMutating = false;
        } else if (state is TaskLoading && state.preservedTasks != null) {
          resolvedTasks = state.preservedTasks!;
          resolvedMode = state.viewMode;
          isMutating = true;
        } else if (state is TaskOperationSuccess && state.preservedTasks != null) {
          resolvedTasks = state.preservedTasks!;
          resolvedMode = state.viewMode;
          isMutating = true;
        } else if (state is TaskError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context
                .read<TaskBloc>()
                .add(LoadTasksEvent(forceRefresh: true)),
          );
        } else {
          return const SizedBox();
        }

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
              return deadline.isBefore(weekFromNow) && !deadline.isBefore(startOfToday);
            }
            return true; // Month/All for now
          }).toList();

          final completedCount = filteredTasks.where((t) => t.status == 'done').length;
          final percentage = filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;

          final scrollView = CustomScrollView(
            slivers: [

              SliverToBoxAdapter(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState is AuthAuthenticated
                        ? authState.user
                        : null;
                    return FlowraAppBar(
                      avatarUrl: user?.profilePictureUrl,
                      userName: user?.fullName,
                      onProfileTap: () => setState(() => _selectedIndex = 4),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: DailyGoalHeader(
                  percentage: percentage,
                  completedTasks: completedCount,
                  totalTasks: filteredTasks.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Daily Flow',
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (filteredTasks.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'No tasks for this view. Start by adding one!',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
        // Resolve task list — either loaded or preserved during a mutation.
        List<Task>? tasks;
        bool isMutating = false;

        if (state is TasksLoaded) {
          tasks = state.tasks;
        } else if (state is TaskLoading && state.preservedTasks != null) {
          tasks = state.preservedTasks;
          isMutating = true;
        } else if (state is TaskOperationSuccess && state.preservedTasks != null) {
          tasks = state.preservedTasks;
          isMutating = true;
        } else if (state is TaskError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<TaskBloc>().add(LoadTasksEvent()),
          );
        }

        if (tasks == null) {
          // Initial load with no data yet.
          return const AppLoader(message: 'Loading tasks…');
        }

        if (tasks.isEmpty) {
          return Center(
            child: Text(
              'No tasks found.',
              style: TextStyle(color: AppColors.getTextSecondary(context)),
            ),
          );
        }

        final pendingCount = tasks.where((t) => t.status != 'done').length;

        final listView = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'To Do',
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$pendingCount pending',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks![index];
                  return TaskListCard(
                    task: task,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailPage(task: task),
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

  Widget? _fabForIndex() {
    // No FAB on the Settings pane (index 4).
    if (_selectedIndex == 4) return null;
    if (_selectedIndex == 1) return _buildAddButton();
    return _buildAIButton();
  }

  Widget _buildAIButton() {
    return GestureDetector(
      onTap: () => showAiAssistantSheet(context),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.psychology, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppColors.getSurface(context),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 0),
            _navItem(Icons.list, 1),
            const SizedBox(width: 48), // Space for FAB
            _navItem(Icons.calendar_month, 2),
            _navItem(Icons.self_improvement, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppColors.secondary : AppColors.textSecondary,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}
