import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

/// Opens the AI task assistant as a full-height modal bottom sheet.
/// Reuses the app-level [TaskBloc] so accepted tasks flow into the list.
Future<void> showAiAssistantSheet(BuildContext context) {
  final taskBloc = context.read<TaskBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: taskBloc,
      child: const _AiAssistantSheet(),
    ),
  ).whenComplete(() {
    // The shared TaskBloc may be left in a suggestions/loading state when the
    // sheet is dismissed without accepting. Reload so the home list always
    // returns to a resolved state instead of a stuck spinner.
    if (taskBloc.state is! TasksLoaded) {
      taskBloc.add(LoadTasksEvent());
    }
  });
}

class _AiAssistantSheet extends StatefulWidget {
  const _AiAssistantSheet();

  @override
  State<_AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<_AiAssistantSheet> {
  final _goalController = TextEditingController();
  final _refineController = TextEditingController();

  List<Task> _drafts = [];
  bool _busy = false;

  @override
  void dispose() {
    _goalController.dispose();
    _refineController.dispose();
    super.dispose();
  }

  void _suggest() {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    context.read<TaskBloc>().add(SuggestTasksEvent(goal));
  }

  void _refine() {
    final instruction = _refineController.text.trim();
    if (instruction.isEmpty || _drafts.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    context.read<TaskBloc>().add(RefineTasksEvent(_drafts, instruction));
    _refineController.clear();
  }

  void _acceptAll() {
    if (_drafts.isEmpty) return;
    context.read<TaskBloc>().add(AcceptSuggestionsEvent(_drafts));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.getBackground(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: BlocListener<TaskBloc, TaskState>(
              listener: (context, state) {
                if (state is TaskSuggestionsLoaded) {
                  setState(() {
                    _drafts = state.suggestions;
                    _busy = false;
                  });
                } else if (state is TaskError) {
                  setState(() => _busy = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  _buildHandle(),
                  _buildHeader(),
                  Expanded(child: _buildBody(scrollController)),
                  _buildFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.getTextSecondary(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Describe a goal, get a task plan',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.getTextSecondary(context),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_busy && _drafts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_drafts.isEmpty) {
      return _buildEmptyPrompt(scrollController);
    }

    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          itemCount: _drafts.length,
          itemBuilder: (context, index) => _buildDraftCard(_drafts[index], index),
        ),
        if (_busy)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyPrompt(ScrollController scrollController) {
    const examples = [
      'Plan a 3-day launch for my app',
      'Prepare for my final exams next week',
      'Organize a weekend home deep-clean',
    ];
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        TextField(
          controller: _goalController,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _suggest(),
          style: TextStyle(color: AppColors.getTextPrimary(context)),
          decoration: InputDecoration(
            hintText: 'What do you want to get done?',
            hintStyle: TextStyle(color: AppColors.getTextSecondary(context)),
            filled: true,
            fillColor: AppColors.getSurface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _suggest,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Generate tasks',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'TRY',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...examples.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _goalController.text = e;
                _suggest();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, size: 18, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e,
                        style: TextStyle(color: AppColors.getTextPrimary(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(Task task, int index) {
    final priorityLabel =
        task.priority == 1 ? 'High' : (task.priority == 2 ? 'Medium' : 'Low');
    final priorityColor = task.priority == 1
        ? AppColors.error
        : (task.priority == 2 ? AppColors.warning : AppColors.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.getTextSecondary(context),
                onPressed: () => setState(() => _drafts.removeAt(index)),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(Icons.timer_outlined, task.duration),
              const SizedBox(width: 8),
              _chip(Icons.flag_outlined, priorityLabel, color: priorityColor),
              if (task.isHard) ...[
                const SizedBox(width: 8),
                _chip(Icons.bolt, 'Deep work', color: AppColors.primary),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    final c = color ?? AppColors.getTextSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_drafts.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _refineController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _refine(),
                  style: TextStyle(color: AppColors.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Refine: "make them shorter"...',
                    hintStyle: const TextStyle(fontSize: 13),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.getBackground(context),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white, size: 18),
                  onPressed: _busy ? null : _refine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _acceptAll,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Add ${_drafts.length} task${_drafts.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
