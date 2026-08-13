import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pills.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Task _task;
  final TextEditingController _notesController = TextEditingController();
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _notesController.text = _task.description;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Directly schedules an unscheduled task: pick a date, then a time, and set
  /// the deadline (start is derived as deadline − duration elsewhere). Reuses
  /// the same update flow as the edit sheet. On success the BlocListener shows
  /// a confirmation and pops back to the list.
  Future<void> _scheduleTask() async {
    final initial = _task.deadline ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final deadline =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    context.read<TaskBloc>().add(
          // Send UTC with a 'Z' suffix — the Go backend binds deadline as an
          // RFC3339 time and rejects a bare local timestamp with a parse error.
          UpdateTaskEvent(_task.id, {'deadline': deadline.toUtc().toIso8601String()}),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        } else if (state is TaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top navigation bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg, vertical: AppDimens.md),
                child: Row(
                  children: [
                    _iconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _iconBtn(
                      icon: Icons.edit_outlined,
                      onTap: () => _showEditSheet(context),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    _iconBtn(
                      icon: Icons.more_horiz_rounded,
                      onTap: () => _showMoreOptions(context),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimens.xs),

                      // ── Tag chips ──────────────────────────────────────────
                      Wrap(
                        spacing: AppDimens.sm,
                        runSpacing: AppDimens.sm,
                        children: [
                          if (_task.isHard)
                            const AppChip(
                              icon: Icons.bolt_rounded,
                              label: 'Deep work',
                              color: AppColors.accent,
                            ),
                          PriorityBadge(priority: _task.priority),
                          StatusPill(status: _task.status),
                        ],
                      ),
                      AppDimens.vGapLg,

                      // ── Title ──────────────────────────────────────────────
                      Text(
                        _task.title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      AppDimens.vGapXl,

                      // ── Unscheduled / deadline card ────────────────────────
                      _buildScheduleCard(context),
                      AppDimens.vGapMd,

                      // ── Completion card ────────────────────────────────────
                      _buildCompletionCard(context),
                      AppDimens.vGapMd,

                      // ── Notes card ─────────────────────────────────────────
                      _buildNotesCard(context),
                      AppDimens.vGapMd,

                      // ── Activity card ──────────────────────────────────────
                      _buildActivityCard(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // ── Bottom action bar ──────────────────────────────────────────
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Schedule Card ──────────────────────────────────────────────────────────
  Widget _buildScheduleCard(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final hasDeadline = _task.deadline != null;

    // ── Unscheduled ─────────────────────────────────────────────────────────
    if (!hasDeadline) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: AppColors.warning, size: 22),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unscheduled',
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('This task has no time slot yet',
                          style:
                              TextStyle(color: textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            AppDimens.vGapLg,
            AppButton(
              label: 'Schedule',
              icon: Icons.event_available_outlined,
              onPressed: _scheduleTask,
            ),
          ],
        ),
      );
    }

    // ── Scheduled — 2×2 grid ────────────────────────────────────────────────
    final deadline = _task.deadline!;
    final durationMinutes = _parseDurationMinutes(_task.duration);
    final startTime = deadline.subtract(Duration(minutes: durationMinutes));
    final endTime = deadline;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.access_time_outlined,
                color: AppColors.secondary,
                label: 'Starts',
                value: _formatTime(startTime),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.timelapse_outlined,
                color: AppColors.accent,
                label: 'Duration',
                value: _task.duration.isEmpty ? '—' : _task.duration,
              ),
            ),
          ],
        ),
        AppDimens.vGapMd,
        Row(
          children: [
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                label: 'Ends',
                value: _formatTime(endTime),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.calendar_today_outlined,
                color: AppColors.warning,
                label: 'Date',
                value: _formatShortDate(deadline),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scheduleInfoCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppDimens.md),
          Text(label,
              style: TextStyle(
                  color: AppColors.getTextSecondary(context), fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Parses durations like "45m", "1h", "1h30m" → total minutes
  int _parseDurationMinutes(String duration) {
    if (duration.isEmpty) return 0;
    int total = 0;
    final hoursMatch = RegExp(r'(\d+)h').firstMatch(duration);
    final minsMatch = RegExp(r'(\d+)m').firstMatch(duration);
    if (hoursMatch != null) total += int.parse(hoursMatch.group(1)!) * 60;
    if (minsMatch != null) total += int.parse(minsMatch.group(1)!);
    return total;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  String _formatShortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  // ─── Completion Card ─────────────────────────────────────────────────────────
  Widget _buildCompletionCard(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final isDone = _task.status == 'done';
    final progress = isDone ? 1.0 : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Completion',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(color: textSecondary, fontSize: 14)),
            ],
          ),
          AppDimens.vGapMd,
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.getBorder(context),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          AppDimens.vGapMd,
          Text(
            isDone ? 'Task completed!' : 'Mark as done when finished.',
            style: TextStyle(color: textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ─── Notes Card ─────────────────────────────────────────────────────────────
  Widget _buildNotesCard(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_outlined, size: 18, color: textSecondary),
              const SizedBox(width: 6),
              Text('Notes',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!_isEditingNotes)
                _miniButton(
                  label: 'Tap to edit',
                  color: textSecondary,
                  bg: AppColors.getSurfaceElevated(context),
                  onTap: () => setState(() => _isEditingNotes = true),
                )
              else
                _miniButton(
                  label: 'Save',
                  color: AppColors.success,
                  bg: AppColors.success.withValues(alpha: 0.15),
                  onTap: () {
                    setState(() => _isEditingNotes = false);
                    context.read<TaskBloc>().add(
                          UpdateTaskEvent(
                              _task.id, {'description': _notesController.text}),
                        );
                  },
                ),
            ],
          ),
          AppDimens.vGapMd,
          _isEditingNotes
              ? TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 8,
                  autofocus: true,
                  style:
                      TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Add context, links, or reminders here…',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                )
              : Text(
                  _task.description.isEmpty
                      ? 'No notes yet. Add context, links, or reminders here…'
                      : _task.description,
                  style: TextStyle(
                    color:
                        _task.description.isEmpty ? textSecondary : textPrimary,
                    fontSize: 14,
                    fontStyle: _task.description.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }

  // ─── Activity Card ───────────────────────────────────────────────────────────
  Widget _buildActivityCard(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final createdAt = _task.createdAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          AppDimens.vGapMd,
          _activityEntry(
            dot: AppColors.success,
            label: 'Task created',
            time:
                createdAt != null ? _formatRelativeDate(createdAt) : 'Just now',
            showConnector: _task.status == 'done',
          ),
          if (_task.status == 'done')
            _activityEntry(
              dot: AppColors.primary,
              label: 'Marked as done',
              time: _task.updatedAt != null
                  ? _formatRelativeDate(_task.updatedAt!)
                  : 'Recently',
              showConnector: false,
            ),
        ],
      ),
    );
  }

  Widget _activityEntry({
    required Color dot,
    required String label,
    required String time,
    required bool showConnector,
  }) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 2),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.getBorder(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppDimens.md),
          Padding(
            padding: EdgeInsets.only(bottom: showConnector ? AppDimens.md : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(time,
                    style: TextStyle(color: textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.xl, AppDimens.md, AppDimens.xl, AppDimens.xl),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        border: Border(top: BorderSide(color: AppColors.getBorder(context))),
      ),
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final isLoading = state is TaskLoading;
          final isDone = _task.status == 'done';

          return Row(
            children: [
              Expanded(
                child: isDone
                    ? AppButton.tonal(
                        label: 'Mark as Todo',
                        icon: Icons.refresh_rounded,
                        loading: isLoading,
                        onPressed: () => _toggleDone(isDone),
                      )
                    : _DoneButton(
                        loading: isLoading,
                        onPressed: () => _toggleDone(isDone),
                      ),
              ),
              const SizedBox(width: AppDimens.md),
              GestureDetector(
                onTap: () => _showDeleteConfirmation(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 22),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleDone(bool isDone) {
    final newStatus = isDone ? 'todo' : 'done';
    context.read<TaskBloc>().add(UpdateTaskEvent(_task.id, {'status': newStatus}));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.getSurface(context),
      shape:
          CircleBorder(side: BorderSide(color: AppColors.getBorder(context))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon,
              color: AppColors.getTextPrimary(context), size: 20),
        ),
      ),
    );
  }

  Widget _miniButton({
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.getTextSecondary(context))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<TaskBloc>().add(DeleteTaskEvent(_task.id));
              },
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppDimens.lg, horizontal: AppDimens.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(context),
              const SizedBox(height: AppDimens.md),
              ListTile(
                leading: Icon(Icons.edit_outlined,
                    color: AppColors.getTextPrimary(context)),
                title: Text('Edit Task',
                    style:
                        TextStyle(color: AppColors.getTextPrimary(context))),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text('Delete Task',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.getBorder(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ─── Edit Bottom Sheet ───────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    // Local edit state — initialised from current task
    final titleCtrl = TextEditingController(text: _task.title);
    final descCtrl = TextEditingController(text: _task.description);
    final durationCtrl = TextEditingController(text: _task.duration);
    int priority = _task.priority;
    bool isHard = _task.isHard;
    bool hasDeadline = _task.deadline != null;
    DateTime deadline =
        _task.deadline ?? DateTime.now().add(const Duration(hours: 1));
    final formKey = GlobalKey<FormState>();

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.sm, top: AppDimens.lg),
          child: Text(
            t,
            style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppDimens.xl,
                right: AppDimens.xl,
                top: AppDimens.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.xxl,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sheetHandle(ctx),
                      const SizedBox(height: AppDimens.lg),
                      Row(
                        children: [
                          Text('Edit Task',
                              style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: Text('Cancel',
                                style: TextStyle(color: textSecondary)),
                          ),
                        ],
                      ),
                      label('Title'),
                      TextFormField(
                        controller: titleCtrl,
                        style: TextStyle(color: textPrimary),
                        decoration:
                            const InputDecoration(hintText: 'Task title'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      label('Description'),
                      TextFormField(
                        controller: descCtrl,
                        style: TextStyle(color: textPrimary),
                        maxLines: 3,
                        decoration: const InputDecoration(
                            hintText: 'What needs to be done?'),
                      ),
                      label('Duration'),
                      TextFormField(
                        controller: durationCtrl,
                        style: TextStyle(color: textPrimary),
                        decoration:
                            const InputDecoration(hintText: 'e.g. 1h 30m'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.trim().contains(RegExp(r'\d'))) {
                            return 'Invalid format (e.g. 1h 30m)';
                          }
                          return null;
                        },
                      ),
                      label('Priority'),
                      _EditPrioritySelector(
                        value: priority,
                        onChanged: (p) => setSheetState(() => priority = p),
                      ),
                      label('Deadline'),
                      Row(
                        children: [
                          Switch(
                            value: hasDeadline,
                            onChanged: (v) =>
                                setSheetState(() => hasDeadline = v),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Text(hasDeadline ? 'Scheduled' : 'No deadline',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 13.5)),
                        ],
                      ),
                      if (hasDeadline) ...[
                        const SizedBox(height: AppDimens.sm),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: deadline,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (date != null && ctx.mounted) {
                              final time = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(deadline),
                              );
                              if (time != null) {
                                setSheetState(() {
                                  deadline = DateTime(date.year, date.month,
                                      date.day, time.hour, time.minute);
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.lg,
                                vertical: AppDimens.lg),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(ctx),
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusSm),
                              border: Border.all(
                                  color: AppColors.getBorder(ctx)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: AppDimens.md),
                                Text(
                                  '${deadline.day}/${deadline.month}/${deadline.year}  ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 14),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    color: textSecondary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimens.lg),
                      Container(
                        padding: const EdgeInsets.fromLTRB(AppDimens.lg,
                            AppDimens.sm, AppDimens.md, AppDimens.sm),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(ctx),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSm),
                          border: Border.all(color: AppColors.getBorder(ctx)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded,
                                color: AppColors.accent, size: 20),
                            const SizedBox(width: AppDimens.md),
                            Expanded(
                              child: Text('Deep work / hard task',
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 14.5)),
                            ),
                            Switch(
                              value: isHard,
                              onChanged: (v) =>
                                  setSheetState(() => isHard = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),
                      AppButton(
                        label: 'Save Changes',
                        onPressed: () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.pop(sheetCtx);
                          final updates = <String, dynamic>{
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'duration': durationCtrl.text.trim(),
                            'priority': priority,
                            'is_hard': isHard,
                            'deadline': hasDeadline
                                ? deadline.toUtc().toIso8601String()
                                : null,
                          };
                          context
                              .read<TaskBloc>()
                              .add(UpdateTaskEvent(_task.id, updates));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day}, ${date.year} $hour:$min $amPm';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final min = date.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$min $amPm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
  }
}

/// Segmented High / Medium / Low selector used in the edit sheet.
class _EditPrioritySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _EditPrioritySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in const [1, 2, 3]) ...[
          Expanded(child: _segment(context, p)),
          if (p != 3) const SizedBox(width: AppDimens.sm),
        ],
      ],
    );
  }

  Widget _segment(BuildContext context, int p) {
    final selected = value == p;
    final color = AppColors.priorityColor(p);
    final label = p == 1 ? 'High' : (p == 2 ? 'Medium' : 'Low');
    return GestureDetector(
      onTap: () => onChanged(p),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: selected ? color : AppColors.getBorder(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.getTextSecondary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Full-width green "Mark Done" button for the bottom bar.
class _DoneButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _DoneButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: AppDimens.sm),
                    Text('Mark Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }
}
