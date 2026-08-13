import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/empty_state.dart';
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
  final FocusNode _aiFocus = FocusNode();

  /// Vertical space the floating bottom nav occupies; content is padded by this
  /// so nothing hides behind it (the nested page paints behind the nav).
  static const double _navClearance = 96;

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
    _aiFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildWeekSelector(),
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
                            padding: const EdgeInsets.fromLTRB(
                                AppDimens.lg, AppDimens.lg, AppDimens.lg, _navClearance),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _buildScheduleItemCard(items[index]);
                            },
                          ),
                        ),
                        if (isLoading)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.15),
                              child:
                                  const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _buildAISchedulingBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.xl, AppDimens.lg, AppDimens.md, AppDimens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule',
                style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.auto_fix_high_rounded,
                    color: AppColors.primary),
                tooltip: 'Fix conflicts',
                onPressed: () {
                  context.read<ScheduleBloc>().add(
                      FixScheduleEvent(DateTime.now().toUtc().toIso8601String()));
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
                            ClearMonthEvent(
                                DateFormat('yyyy-MM').format(_selectedDate)),
                          ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: AppDimens.sm),
                        Text('Regenerate All'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear_day',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded,
                            size: 20, color: AppColors.error),
                        SizedBox(width: AppDimens.sm),
                        Text('Clear Day',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_week',
                    child: Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            size: 20, color: AppColors.error),
                        SizedBox(width: AppDimens.sm),
                        Text('Clear Week',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_month',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 20, color: AppColors.error),
                        SizedBox(width: AppDimens.sm),
                        Text('Clear Month',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_horiz_rounded,
                    color: AppColors.getTextPrimary(context)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final today = DateTime.now();
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.lg, vertical: AppDimens.sm),
        itemCount: 14, // Show 2 weeks
        itemBuilder: (context, index) {
          final date = today
              .subtract(Duration(days: today.weekday - 1))
              .add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          final dayName = DateFormat('E').format(date).toUpperCase();
          final dayNum = DateFormat('d').format(date);

          return GestureDetector(
            onTap: () => _changeDate(date),
            child: Container(
              width: 54,
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.xs),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isToday
                          ? AppColors.primary
                          : AppColors.getBorder(context)),
                  width: isToday && !isSelected ? 1.5 : 1,
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
                          : AppColors.getTextSecondary(context),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.getTextPrimary(context),
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
        padding: const EdgeInsets.only(top: 48, bottom: _navClearance),
        child: EmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'No schedule yet',
          message:
              'Your day is clear. Build a schedule from your active tasks, or ask AI to plan your day.',
          primaryLabel: 'Generate schedule',
          onPrimary: () {
            context
                .read<ScheduleBloc>()
                .add(RegenerateScheduleEvent(_dateToStr(_selectedDate)));
          },
          secondaryLabel: 'Ask AI to plan my day',
          onSecondary: () => _aiFocus.requestFocus(),
        ),
      ),
    );
  }

  Widget _buildScheduleItemCard(ScheduleItem item) {
    final startTimeStr = DateFormat('h:mm a').format(item.startTime.toLocal());
    final endTimeStr = DateFormat('h:mm a').format(item.endTime.toLocal());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = AppColors.getTextSecondary(context);
    IconData statusIcon = Icons.pending_actions_rounded;

    if (item.status == 'done') {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (item.status == 'skipped') {
      statusColor = AppColors.warning;
      statusIcon = Icons.skip_next_rounded;
    }

    final accent = item.isHard ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: item.isHard
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.getBorder(context),
          width: item.isHard ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF12131A).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.lg),
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
                                fontWeight: FontWeight.w700,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: const Text(
                                'Hard',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: AppDimens.sm),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '$startTimeStr – $endTimeStr',
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
              PopupMenuButton<String>(
                onSelected: (value) => _handleItemAction(item, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'done',
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded, color: AppColors.success),
                        SizedBox(width: AppDimens.sm),
                        Text('Mark Done'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'skipped',
                    child: Row(
                      children: [
                        Icon(Icons.skip_next_rounded, color: AppColors.warning),
                        SizedBox(width: AppDimens.sm),
                        Text('Skip'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, color: AppColors.info),
                        SizedBox(width: AppDimens.sm),
                        Text('Adjust Time'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: AppColors.error),
                        SizedBox(width: AppDimens.sm),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.getTextSecondary(context)),
              ),
            ],
          ),
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
            const SizedBox(height: AppDimens.lg),
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

  Widget _buildAISchedulingBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.md + _navClearance - 12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(top: BorderSide(color: AppColors.getBorder(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiController,
              focusNode: _aiFocus,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendAiPrompt(),
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Ask AI: "Plan meeting after 2pm"…',
                hintStyle: const TextStyle(fontSize: 14),
                isDense: true,
                filled: true,
                fillColor: AppColors.getBackground(context),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg, vertical: AppDimens.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sendAiPrompt,
              child: const Padding(
                padding: EdgeInsets.all(AppDimens.md),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendAiPrompt() {
    final prompt = _aiController.text.trim();
    if (prompt.isEmpty) return;
    context
        .read<ScheduleBloc>()
        .add(AIScheduleEvent(_dateToStr(_selectedDate), prompt));
    _aiController.clear();
    _aiFocus.unfocus();
  }
}
