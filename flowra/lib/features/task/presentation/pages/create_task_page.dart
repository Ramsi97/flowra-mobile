import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: '1h');
  int _priority = 1;
  bool _isHard = false;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(title: const Text('New Task')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.xl,
            AppDimens.sm,
            AppDimens.xl,
            AppDimens.xxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Title'),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: AppColors.getTextPrimary(context)),
                  decoration:
                      const InputDecoration(hintText: 'e.g. Design Flowra UI'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                AppDimens.vGapLg,
                _buildLabel('Description'),
                TextFormField(
                  controller: _descController,
                  style: TextStyle(color: AppColors.getTextPrimary(context)),
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'What needs to be done?'),
                ),
                AppDimens.vGapLg,
                _buildLabel('Duration'),
                TextFormField(
                  controller: _durationController,
                  style: TextStyle(color: AppColors.getTextPrimary(context)),
                  decoration: const InputDecoration(hintText: '1h 30m'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final reg = RegExp(r'^(\d+h)?\s*(\d+m)?$');
                    final trimmed = v.trim();
                    if (!reg.hasMatch(trimmed) || trimmed.isEmpty) {
                      return 'Invalid format (e.g. 1h 30m)';
                    }
                    if (!trimmed.contains(RegExp(r'\d'))) {
                      return 'Invalid format (e.g. 1h 30m)';
                    }
                    return null;
                  },
                ),
                AppDimens.vGapLg,
                _buildLabel('Priority'),
                _PrioritySelector(
                  value: _priority,
                  onChanged: (p) => setState(() => _priority = p),
                ),
                AppDimens.vGapLg,
                _buildLabel('Deadline'),
                InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.lg,
                      vertical: AppDimens.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEE, MMM d · HH:mm').format(_deadline),
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
                AppDimens.vGapLg,
                _DeepWorkToggle(
                  value: _isHard,
                  onChanged: (v) => setState(() => _isHard = v),
                ),
                AppDimens.vGapXl,
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    return AppButton(
                      label: 'Create Task',
                      loading: state is TaskLoading,
                      onPressed: _submit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time != null) {
      setState(() {
        _deadline = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.getTextSecondary(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = Task(
        id: '', // Backend generates ID
        userId: '', // Backend handles this
        title: _titleController.text,
        description: _descController.text,
        duration: _durationController.text,
        priority: _priority,
        isHard: _isHard,
        status: 'todo',
        deadline: _deadline,
      );
      context.read<TaskBloc>().add(CreateTaskEvent(task));
    }
  }
}

/// Segmented High / Medium / Low priority selector.
class _PrioritySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PrioritySelector({required this.value, required this.onChanged});

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
        padding: const EdgeInsets.symmetric(vertical: 14),
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

class _DeepWorkToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DeepWorkToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.sm, AppDimens.md, AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deep work',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Needs focus — schedule in a quiet block',
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
