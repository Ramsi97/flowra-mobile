import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/bloc/task_state.dart';
import '../../../task/domain/entities/task.dart';
import '../widgets/daily_flow_tile.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/up_next_card.dart';
import '../widgets/quick_actions_row.dart';
import '../../../task/presentation/pages/create_task_page.dart';
import '../../../task/presentation/pages/task_detail_page.dart';
import '../../../auth/presentation/bloc/bloc/auth_bloc.dart';
import '../../../task/presentation/widgets/task_list_card.dart';
import '../../../task/presentation/pages/ai_assistant_sheet.dart';
import '../../../schedule/presentation/pages/schedule_page.dart';
import '../../../focus/presentation/pages/focus_page.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/settings_button.dart';
import '../../../focus/presentation/bloc/focus_bloc.dart';
import '../../../focus/presentation/bloc/focus_event.dart';
import '../../../focus/presentation/bloc/focus_state.dart';
import '../../../schedule/domain/entities/schedule_item.dart';

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
    context.read<FocusBloc>().add(const LoadFocusStatusEvent());
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
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
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
        final pendingTasks =
            filteredTasks.where((t) => t.status != 'done').toList();
        final pendingCount = pendingTasks.length;
        final highCount = pendingTasks.where((t) => t.priority == 1).length;
        final percentage =
            filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;

        // The single "do this next" task: soonest deadline among unfinished
        // tasks, falling back to the highest priority when none have a deadline.
        Task? nextTask;
        if (pendingTasks.isNotEmpty) {
          final withDeadline =
              pendingTasks.where((t) => t.deadline != null).toList()
                ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
          if (withDeadline.isNotEmpty) {
            nextTask = withDeadline.first;
          } else {
            final byPriority = [...pendingTasks]
              ..sort((a, b) => a.priority.compareTo(b.priority));
            nextTask = byPriority.first;
          }
        }

        final scrollView = CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: HomeGreetingHeader(trailing: SettingsButton()),
            ),
            SliverToBoxAdapter(
              child: TodaySummaryCard(
                percentage: percentage,
                done: completedCount,
                pending: pendingCount,
                highPriority: highCount,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimens.lg)),
            SliverToBoxAdapter(
              child: BlocBuilder<FocusBloc, FocusState>(
                builder: (context, focusState) {
                  ScheduleItem? activeItem;
                  if (focusState is FocusLoaded && focusState.status.isActive) {
                    activeItem = focusState.status.currentItem;
                  }
                  return UpNextCard(
                    nextTask: nextTask,
                    activeFocusItem: activeItem,
                    onStartFocus: () => setState(() => _selectedIndex = 3),
                    onPlanDay: () => showAiAssistantSheet(context),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimens.lg)),
            SliverToBoxAdapter(
              child: QuickActionsRow(
                onAddTask: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                ),
                onPlanAi: () => showAiAssistantSheet(context),
                onFocus: () => setState(() => _selectedIndex = 3),
                onSchedule: () => setState(() => _selectedIndex = 2),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.xl,
                AppDimens.xl,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.xxl),
                  child: EmptyState(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Your day is clear',
                    message:
                        'No tasks scheduled for this view. Add one or ask the AI to plan your day.',
                    primaryLabel: 'Add a task',
                    onPrimary: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                    ),
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
            AppHeader(
              title: 'Tasks',
              subtitle: '$pendingCount pending',
              trailing: const SettingsButton(),
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
