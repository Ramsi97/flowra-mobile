import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1117) : AppColors.lightBackground;
    final cardColor = isDark ? const Color(0xFF1A1D27) : AppColors.lightSurface;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? const Color(0xFF8B8FA8) : AppColors.lightTextSecondary;

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is TaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top navigation bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios_new, size: 14, color: textPrimary),
                            const SizedBox(width: 4),
                            Text('Back', style: TextStyle(color: textPrimary, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _iconBtn(
                      icon: Icons.edit_outlined,
                      color: cardColor,
                      iconColor: textPrimary,
                      onTap: () => _showEditSheet(context),
                    ),
                    const SizedBox(width: 8),
                    _iconBtn(
                      icon: Icons.more_horiz,
                      color: cardColor,
                      iconColor: textPrimary,
                      onTap: () => _showMoreOptions(context),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // ── Tag chips ──────────────────────────────────────────
                      Row(
                        children: [
                          if (_task.isHard) ...[
                            _chip(
                              label: 'Deep Work',
                              icon: Icons.psychology_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _chip(
                            label: _getPriorityLabel(),
                            icon: Icons.flag,
                            color: _getPriorityColor(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Title + status ─────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.laptop_mac_outlined, color: textSecondary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _task.title,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStatusColor(),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusLabel(),
                                      style: TextStyle(color: textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Divider ────────────────────────────────────────────
                      Divider(color: Colors.white.withOpacity(0.06), height: 1),
                      const SizedBox(height: 20),

                      // ── Unscheduled / deadline card ────────────────────────
                      _buildScheduleCard(context, cardColor, textPrimary, textSecondary),
                      const SizedBox(height: 12),

                      // ── Completion card ────────────────────────────────────
                      _buildCompletionCard(context, cardColor, textPrimary, textSecondary),
                      const SizedBox(height: 12),

                      // ── Notes card ─────────────────────────────────────────
                      _buildNotesCard(context, cardColor, textPrimary, textSecondary),
                      const SizedBox(height: 12),

                      // ── Activity card ──────────────────────────────────────
                      _buildActivityCard(context, cardColor, textPrimary, textSecondary),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // ── Bottom action bar ──────────────────────────────────────────
              _buildBottomBar(context, cardColor),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Schedule Card ──────────────────────────────────────────────────────────
  Widget _buildScheduleCard(BuildContext context, Color cardColor, Color textPrimary, Color textSecondary) {
    final hasDeadline = _task.deadline != null;

    // ── Unscheduled ─────────────────────────────────────────────────────────
    if (!hasDeadline) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unscheduled',
                    style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'This task has no time slot yet',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
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
        // Row 1 — Starts | Duration
        Row(
          children: [
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.access_time_outlined,
                iconColor: AppColors.secondary,
                label: 'Starts',
                value: _formatTime(startTime),
                valueColor: AppColors.secondary,
                cardColor: cardColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.timelapse_outlined,
                iconColor: AppColors.accent,
                label: 'Duration',
                value: _task.duration.isEmpty ? '—' : _task.duration,
                valueColor: AppColors.accent,
                cardColor: cardColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2 — Ends | Date
        Row(
          children: [
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                label: 'Ends',
                value: _formatTime(endTime),
                valueColor: AppColors.success,
                cardColor: cardColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _scheduleInfoCard(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.warning,
                label: 'Date',
                value: _formatShortDate(deadline),
                valueColor: AppColors.warning,
                cardColor: cardColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scheduleInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: iconColor.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 17, fontWeight: FontWeight.bold),
          ),
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
  Widget _buildCompletionCard(BuildContext context, Color cardColor, Color textPrimary, Color textSecondary) {
    final isDone = _task.status == 'done';
    final progress = isDone ? 1.0 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Completion',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isDone ? 'Task completed!' : 'Mark as done when finished.',
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Notes Card ─────────────────────────────────────────────────────────────
  Widget _buildNotesCard(BuildContext context, Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Notes',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!_isEditingNotes)
                GestureDetector(
                  onTap: () => setState(() => _isEditingNotes = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tap to edit',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() => _isEditingNotes = false);
                    context.read<TaskBloc>().add(
                      UpdateTaskEvent(_task.id, {'description': _notesController.text}),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _isEditingNotes
              ? TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 8,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 13, height: 1.5),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add context, links, or reminders here...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                )
              : Text(
                  _task.description.isEmpty
                      ? 'No notes yet. Add context, links, or reminders here...'
                      : _task.description,
                  style: TextStyle(
                    color: _task.description.isEmpty ? textSecondary : textPrimary,
                    fontSize: 13,
                    fontStyle: _task.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }

  // ─── Activity Card ───────────────────────────────────────────────────────────
  Widget _buildActivityCard(BuildContext context, Color cardColor, Color textPrimary, Color textSecondary) {
    final createdAt = _task.createdAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _activityEntry(
            dot: AppColors.success,
            label: 'Task created',
            time: createdAt != null ? _formatRelativeDate(createdAt) : 'Just now',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          if (_task.status == 'done') ...[
            const SizedBox(height: 12),
            _activityEntry(
              dot: AppColors.primary,
              label: 'Marked as done',
              time: _task.updatedAt != null ? _formatRelativeDate(_task.updatedAt!) : 'Recently',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityEntry({
    required Color dot,
    required String label,
    required String time,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 2),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            Container(width: 1.5, height: 24, color: Colors.white.withOpacity(0.08)),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(color: textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, Color cardColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final isLoading = state is TaskLoading;
          final isDone = _task.status == 'done';

          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () {
                          final newStatus = isDone ? 'todo' : 'done';
                          context.read<TaskBloc>().add(UpdateTaskEvent(_task.id, {'status': newStatus}));
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.white.withOpacity(0.08) : AppColors.success,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDone ? Icons.refresh : Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isDone ? 'Mark as Todo' : 'Mark Done',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showDeleteConfirmation(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _chip({required String label, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getSurface(context),
          title: Text('Delete Task', style: TextStyle(color: AppColors.getTextPrimary(context))),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<TaskBloc>().add(DeleteTaskEvent(_task.id));
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.getTextPrimary(context)),
              title: Text('Edit Task', style: TextStyle(color: AppColors.getTextPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Task', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Edit Bottom Sheet ───────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF13161F) : AppColors.lightBackground;
    final cardColor = isDark ? const Color(0xFF1A1D27) : AppColors.lightSurface;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? const Color(0xFF8B8FA8) : AppColors.lightTextSecondary;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    // Local edit state — initialised from current task
    final titleCtrl = TextEditingController(text: _task.title);
    final descCtrl = TextEditingController(text: _task.description);
    final durationCtrl = TextEditingController(text: _task.duration);
    int priority = _task.priority;
    bool isHard = _task.isHard;
    bool hasDeadline = _task.deadline != null;
    DateTime deadline = _task.deadline ?? DateTime.now().add(const Duration(hours: 1));
    final formKey = GlobalKey<FormState>();

    InputDecoration fieldDeco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        );

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 20),
          child: Text(
            t,
            style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1),
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Handle ────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Sheet title ────────────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Edit Task',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: Text('Cancel', style: TextStyle(color: textSecondary)),
                          ),
                        ],
                      ),

                      // ── Title ─────────────────────────────────────────────
                      label('TITLE'),
                      TextFormField(
                        controller: titleCtrl,
                        style: TextStyle(color: textPrimary),
                        decoration: fieldDeco('Task title'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      // ── Description ───────────────────────────────────────
                      label('DESCRIPTION'),
                      TextFormField(
                        controller: descCtrl,
                        style: TextStyle(color: textPrimary),
                        maxLines: 3,
                        decoration: fieldDeco('What needs to be done?'),
                      ),

                      // ── Duration + Priority ───────────────────────────────
                      label('DURATION'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: durationCtrl,
                              style: TextStyle(color: textPrimary),
                              decoration: fieldDeco('e.g. 1h 30m'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final trimmed = v.trim();
                                if (!trimmed.contains(RegExp(r'\d'))) return 'Invalid format (e.g. 1h 30m)';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: priority,
                              dropdownColor: cardColor,
                              style: TextStyle(color: textPrimary),
                              decoration: fieldDeco('').copyWith(labelText: 'Priority', labelStyle: TextStyle(color: textSecondary)),
                              items: [1, 2, 3].map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p == 1 ? 'High' : (p == 2 ? 'Medium' : 'Low'),
                                    style: TextStyle(color: textPrimary),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setSheetState(() => priority = v!),
                            ),
                          ),
                        ],
                      ),

                      // ── Deadline toggle ───────────────────────────────────
                      label('DEADLINE'),
                      Row(
                        children: [
                          Switch(
                            value: hasDeadline,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setSheetState(() => hasDeadline = v),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasDeadline ? 'Scheduled' : 'No deadline',
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      if (hasDeadline) ...
                        [
                          const SizedBox(height: 8),
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
                                    deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${deadline.day}/${deadline.month}/${deadline.year}  ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: textPrimary, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.chevron_right, color: textSecondary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],

                      // ── Deep Work toggle ──────────────────────────────────
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology_outlined, color: AppColors.accent, size: 20),
                            const SizedBox(width: 10),
                            Text('Deep Work / Hard Task', style: TextStyle(color: textPrimary, fontSize: 14)),
                            const Spacer(),
                            Switch(
                              value: isHard,
                              activeColor: AppColors.accent,
                              onChanged: (v) => setSheetState(() => isHard = v),
                            ),
                          ],
                        ),
                      ),

                      // ── Save button ───────────────────────────────────────
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            Navigator.pop(sheetCtx);
                            final updates = <String, dynamic>{
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'duration': durationCtrl.text.trim(),
                              'priority': priority,
                              'is_hard': isHard,
                              'deadline': hasDeadline ? deadline.toIso8601String() : null,
                            };
                            context.read<TaskBloc>().add(UpdateTaskEvent(_task.id, updates));
                          },
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
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

  Color _getPriorityColor() {
    switch (_task.priority) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  String _getPriorityLabel() {
    switch (_task.priority) {
      case 1:
        return 'High Priority';
      case 2:
        return 'Medium Priority';
      default:
        return 'Low Priority';
    }
  }

  Color _getStatusColor() {
    switch (_task.status) {
      case 'done':
        return AppColors.success;
      case 'skipped':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusLabel() {
    switch (_task.status) {
      case 'done':
        return 'Completed';
      case 'skipped':
        return 'Skipped';
      default:
        return 'In progress';
    }
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
