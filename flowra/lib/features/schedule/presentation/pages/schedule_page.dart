import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/schedule_item.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _selectedDate;
  final TextEditingController _aiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadDay();
  }

  void _loadDay() {
    final dateStr = _dateToStr(_selectedDate);
    context.read<ScheduleBloc>().add(LoadScheduleEvent(dateStr));
  }

  String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    context.read<ScheduleBloc>().add(ChangeDateEvent(date));
  }

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ScheduleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(textColor),
              _buildWeekSelector(textColor),
              Expanded(
                child: BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    List<ScheduleItem> items = [];
                    bool isLoading = false;

                    if (state is ScheduleLoading) {
                      isLoading = true;
                      items = state.preservedItems ?? [];
                    } else if (state is ScheduleLoaded) {
                      items = state.items;
                    } else if (state is ScheduleError) {
                      items = state.preservedItems ?? [];
                    }

                    if (isLoading && items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () async {
                            _loadDay();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _buildScheduleItemCard(items[index], isDark);
                            },
                          ),
                        ),
                        if (isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.15),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _buildAISchedulingBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.build_outlined, color: AppColors.primary),
                tooltip: 'Fix conflicts',
                onPressed: () {
                  context
                      .read<ScheduleBloc>()
                      .add(FixScheduleEvent(DateTime.now().toUtc().toIso8601String()));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'regenerate') {
                    context
                        .read<ScheduleBloc>()
                        .add(RegenerateScheduleEvent(_dateToStr(_selectedDate)));
                  } else if (value == 'clear_day') {
                    _confirmClear(
                      title: 'Clear this day?',
                      message:
                          'This removes every scheduled block for ${DateFormat('EEE, MMM d').format(_selectedDate)}.',
                      onConfirm: () => context
                          .read<ScheduleBloc>()
                          .add(ClearDayEvent(_dateToStr(_selectedDate))),
                    );
                  } else if (value == 'clear_week') {
                    final monday = _selectedDate
                        .subtract(Duration(days: _selectedDate.weekday - 1));
                    _confirmClear(
                      title: 'Clear this week?',
                      message:
                          'This removes every scheduled block for the week of ${DateFormat('MMM d').format(monday)}.',
                      onConfirm: () => context
                          .read<ScheduleBloc>()
                          .add(ClearWeekEvent(_dateToStr(monday))),
                    );
                  } else if (value == 'clear_month') {
                    _confirmClear(
                      title: 'Clear this month?',
                      message:
                          'This removes every scheduled block in ${DateFormat('MMMM yyyy').format(_selectedDate)}.',
                      onConfirm: () => context.read<ScheduleBloc>().add(
                            ClearMonthEvent(DateFormat('yyyy-MM').format(_selectedDate)),
                          ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text('Regenerate All'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_day',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Clear Day', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_week',
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Clear Week', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_month',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Clear Month', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_horiz, color: textColor),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeekSelector(Color textColor) {
    final today = DateTime.now();
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // Show 2 weeks
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: today.weekday - 1)).add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final dayName = DateFormat('E').format(date).toUpperCase();
          final dayNum = DateFormat('d').format(date);

          return GestureDetector(
            onTap: () => _changeDate(date),
            child: Container(
              width: 54,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isSelected && Theme.of(context).brightness == Brightness.light)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade200,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : textColor.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Schedule for Today',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your day is clear! Generate a customized schedule from your active task list or ask AI to plan your day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.getTextSecondary(context), height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<ScheduleBloc>()
                    .add(LoadScheduleEvent(_dateToStr(_selectedDate)));
              },
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: const Text('Generate Day Schedule', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItemCard(ScheduleItem item, bool isDark) {
    final startTimeStr = DateFormat('h:mm a').format(item.startTime.toLocal());
    final endTimeStr = DateFormat('h:mm a').format(item.endTime.toLocal());
    
    Color statusColor = AppColors.getTextSecondary(context);
    IconData statusIcon = Icons.pending_actions;

    if (item.status == 'done') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (item.status == 'skipped') {
      statusColor = AppColors.warning;
      statusIcon = Icons.skip_next;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isHard 
              ? AppColors.error.withOpacity(0.5) 
              : Colors.transparent,
          width: item.isHard ? 1.5 : 0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: item.isHard ? AppColors.error : AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: item.status == 'done'
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.status == 'done'
                                  ? AppColors.getTextSecondary(context)
                                  : AppColors.getTextPrimary(context),
                            ),
                          ),
                        ),
                        if (item.isHard)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hard',
                              style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '$startTimeStr - $endTimeStr',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        const Spacer(),
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            PopupMenuButton<String>(
              onSelected: (value) => _handleItemAction(item, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'done',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Mark Done'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'skipped',
                  child: Row(
                    children: [
                      Icon(Icons.skip_next, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text('Skip'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Adjust Time'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert, color: AppColors.getTextSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemAction(ScheduleItem item, String action) {
    if (action == 'done' || action == 'skipped') {
      // Actually updates matching task/schedule item status
      context.read<ScheduleBloc>().add(UpdateScheduleItemEvent(
        item.id,
        {'status': action},
      ));
    } else if (action == 'delete') {
      context.read<ScheduleBloc>().add(DeleteScheduleItemEvent(item.id));
    } else if (action == 'edit') {
      _showAdjustTimeDialog(item);
    }
  }

  void _showAdjustTimeDialog(ScheduleItem item) {
    final startTimeController = TextEditingController(
      text: DateFormat('HH:mm').format(item.startTime.toLocal()),
    );
    final durationController = TextEditingController(
      text: item.duration.inMinutes.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Scheduled Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startTimeController,
              decoration: const InputDecoration(
                labelText: 'Start Time (HH:MM)',
                hintText: 'e.g., 09:30',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'e.g., 60',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDuration = int.tryParse(durationController.text);
              if (newDuration == null) return;

              final parts = startTimeController.text.split(':');
              if (parts.length != 2) return;
              final hour = int.tryParse(parts[0]);
              final min = int.tryParse(parts[1]);
              if (hour == null || min == null) return;

              final originalLocal = item.startTime.toLocal();
              final localNewTime = DateTime(
                originalLocal.year,
                originalLocal.month,
                originalLocal.day,
                hour,
                min,
              );

              context.read<ScheduleBloc>().add(
                UpdateScheduleItemEvent(
                  item.id,
                  {
                    'start_time': localNewTime.toUtc().toIso8601String(),
                    'duration_minutes': newDuration,
                  },
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmClear({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAISchedulingBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiController,
              decoration: InputDecoration(
                hintText: 'Ask AI: "Plan meeting after 2pm"...',
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                fillColor: isDark 
                    ? AppColors.darkBackground 
                    : Colors.grey.shade100,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: () {
                final prompt = _aiController.text.trim();
                if (prompt.isEmpty) return;
                context.read<ScheduleBloc>().add(
                      AIScheduleEvent(_dateToStr(_selectedDate), prompt),
                    );
                _aiController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}
