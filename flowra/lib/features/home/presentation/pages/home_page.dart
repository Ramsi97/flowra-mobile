import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/bloc/task_state.dart';
import '../widgets/daily_flow_tile.dart';
import '../widgets/daily_goal_header.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(),
            const Center(child: Text('Tasks View', style: TextStyle(color: Colors.white, fontSize: 24))),
            const Center(child: Text('Calendar View', style: TextStyle(color: Colors.white, fontSize: 24))),
            const Center(child: Text('Settings View', style: TextStyle(color: Colors.white, fontSize: 24))),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildAIButton(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboard() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TasksLoaded) {
          final completedCount = state.tasks.where((t) => t.status == 'done').length;
          final percentage = state.tasks.isEmpty ? 0.0 : completedCount / state.tasks.length;

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'Flowra',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
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
                  totalTasks: state.tasks.length,
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Daily Flow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (state.tasks.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'No tasks for today. Start by adding one!',
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
                          task: state.tasks[index],
                          isFirst: index == 0,
                          isLast: index == state.tasks.length - 1,
                        );
                      },
                      childCount: state.tasks.length,
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
      color: AppColors.surface,
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
