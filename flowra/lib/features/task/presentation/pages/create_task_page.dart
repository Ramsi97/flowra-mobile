import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else if (state is TaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        appBar: AppBar(
          title: const Text('New Task'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.getTextPrimary(context),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('TITLE'),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: AppColors.getTextPrimary(context)),
                  decoration: _inputDecoration('e.g., Design Flowra UI'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                _buildLabel('DESCRIPTION'),
                TextFormField(
                  controller: _descController,
                  style: TextStyle(color: AppColors.getTextPrimary(context)),
                  maxLines: 3,
                  decoration: _inputDecoration('What needs to be done?'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('DURATION'),
                          TextFormField(
                            controller: _durationController,
                            style: TextStyle(color: AppColors.getTextPrimary(context)),
                            decoration: _inputDecoration('1h 30m'),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('PRIORITY'),
                          DropdownButtonFormField<int>(
                            initialValue: _priority,
                            dropdownColor: AppColors.getSurface(context),
                            style: TextStyle(color: AppColors.getTextPrimary(context)),
                            decoration: _inputDecoration(''),
                            items: [1, 2, 3].map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(p == 1 ? 'High' : (p == 2 ? 'Medium' : 'Low')),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _priority = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('DEADLINE'),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      if (!mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_deadline),
                      );
                      if (time != null) {
                        setState(() {
                          _deadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_deadline.day}/${_deadline.month}/${_deadline.year} ${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: AppColors.getTextPrimary(context)),
                        ),
                        const Icon(Icons.calendar_today, color: AppColors.secondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Deep Work / Hard Task',
                        style: TextStyle(
                            color: AppColors.getTextPrimary(context), fontSize: 16)),
                    Switch(
                      value: _isHard,
                      activeTrackColor: AppColors.secondary,
                      onChanged: (v) => setState(() => _isHard = v),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    final isLoading = state is TaskLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: _roundedRectangleCircular(16),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Create Task', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
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

  Color get _borderColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.grey.shade300;

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.getTextSecondary(context),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.getTextSecondary(context).withOpacity(0.6)),
      filled: true,
      fillColor: AppColors.getSurface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
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

  // Helper for consistent border radius
  static RoundedRectangleBorder _roundedRectangleCircular(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
}
