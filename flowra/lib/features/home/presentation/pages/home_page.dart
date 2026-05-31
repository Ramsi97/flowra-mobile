import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/bloc/task_state.dart';
import '../widgets/daily_flow_tile.dart';
import '../widgets/daily_goal_header.dart';
import '../../../task/presentation/pages/create_task_page.dart';
import '../../../settings/presentation/bloc/theme_bloc.dart';
import '../../../settings/presentation/bloc/theme_event.dart';
import '../../../settings/presentation/bloc/theme_state.dart';

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
    context.read<TaskBloc>().add(LoadTasksEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(),
            _buildTaskList(),
            const Center(child: Text('Calendar View', style: TextStyle(color: Colors.white, fontSize: 24))),
            _buildSettings(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedIndex == 1 ? _buildAddButton() : _buildAIButton(),
      bottomNavigationBar: _buildBottomNav(),
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
              padding: const EdgeInsets.only(bottom: 32.0, top: 16),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
          ],
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
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TasksLoaded) {
          final now = DateTime.now();
          final filteredTasks = state.tasks.where((t) {
            if (t.deadline == null) return true;
            if (state.viewMode == TaskViewMode.day) {
              return t.deadline!.day == now.day && t.deadline!.month == now.month && t.deadline!.year == now.year;
            } else if (state.viewMode == TaskViewMode.week) {
              final weekFromNow = now.add(const Duration(days: 7));
              return t.deadline!.isBefore(weekFromNow);
            }
            return true; // Month/All for now
          }).toList();

          final completedCount = filteredTasks.where((t) => t.status == 'done').length;
          final percentage = filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: TaskViewMode.values.map((mode) {
                      final isSelected = state.viewMode == mode;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(mode.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) => context.read<TaskBloc>().add(ChangeViewModeEvent(mode)),
                          selectedColor: AppColors.secondary,
                          backgroundColor: AppColors.getSurface(context),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32.0),
                  child: Text(
                    'Flowra',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
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
        } else if (state is TaskError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TasksLoaded) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.tasks.length,
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              return Card(
                color: AppColors.getSurface(context),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(task.title, style: TextStyle(color: AppColors.getTextPrimary(context))),
                  subtitle: Text(task.description, style: TextStyle(color: AppColors.getTextSecondary(context))),
                  trailing: Icon(
                    Icons.circle,
                    color: task.priority == 1 ? Colors.red : task.priority == 2 ? Colors.orange : Colors.green,
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildAIButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Assistant coming soon!')),
        );
      },
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
            _navItem(Icons.settings, 3),
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
