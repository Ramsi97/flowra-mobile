import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pills.dart';
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
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
        color: AppColors.getBorder(context),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.xl, AppDimens.md, AppDimens.md, AppDimens.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Describe a goal, get a task plan',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
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
          padding: const EdgeInsets.fromLTRB(
              AppDimens.xl, AppDimens.xs, AppDimens.xl, AppDimens.lg),
          itemCount: _drafts.length,
          itemBuilder: (context, index) => _buildDraftCard(_drafts[index], index),
        ),
        if (_busy)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
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
      padding: const EdgeInsets.fromLTRB(
          AppDimens.xl, AppDimens.sm, AppDimens.xl, AppDimens.lg),
      children: [
        TextField(
          controller: _goalController,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _suggest(),
          style: TextStyle(color: AppColors.getTextPrimary(context)),
          decoration: InputDecoration(
            hintText: 'What do you want to get done?',
          ),
        ),
        AppDimens.vGapLg,
        AppButton(
          label: 'Generate tasks',
          icon: Icons.auto_awesome_rounded,
          onPressed: _suggest,
        ),
        AppDimens.vGapXxl,
        Text(
          'TRY',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        AppDimens.vGapMd,
        ...examples.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: Material(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                onTap: () {
                  _goalController.text = e;
                  _suggest();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.lg, vertical: AppDimens.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 18, color: AppColors.secondary),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Text(
                          e,
                          style: TextStyle(
                              color: AppColors.getTextPrimary(context)),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.getTextSecondary(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(Task task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.getBorder(context)),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.getTextSecondary(context),
                onPressed: () => setState(() => _drafts.removeAt(index)),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: AppDimens.xs),
            Text(
              task.description,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          AppDimens.vGapMd,
          Wrap(
            spacing: AppDimens.sm,
            runSpacing: AppDimens.sm,
            children: [
              AppChip(icon: Icons.timer_outlined, label: task.duration),
              PriorityBadge(priority: task.priority),
              if (task.isHard)
                const AppChip(
                  icon: Icons.bolt_rounded,
                  label: 'Deep work',
                  color: AppColors.accent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_drafts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg,
          AppDimens.md + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(top: BorderSide(color: AppColors.getBorder(context))),
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
                    hintText: 'Refine: "make them shorter"…',
                    hintStyle: const TextStyle(fontSize: 13),
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
                color: AppColors.secondary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _busy ? null : _refine,
                  child: const Padding(
                    padding: EdgeInsets.all(AppDimens.md),
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          AppDimens.vGapMd,
          AppButton(
            label: 'Add ${_drafts.length} task${_drafts.length == 1 ? '' : 's'}',
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _acceptAll,
          ),
        ],
      ),
    );
  }
}
