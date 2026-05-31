import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Task'),
        backgroundColor: Colors.transparent,
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
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g., Design Flowra UI'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _buildLabel('DESCRIPTION'),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
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
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('1h 30m'),
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
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(''),
                          items: [1, 2, 3].map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p == 1 ? 'High' : p == 2 ? 'Medium' : 'Low'),
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
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                        style: const TextStyle(color: Colors.white),
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
                  const Text('Deep Work / Hard Task', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Switch(
                    value: _isHard,
                    activeTrackColor: AppColors.secondary,
                    onChanged: (v) => setState(() => _isHard = v),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: _roundedRectangleCircular(16),
                  ),
                  child: const Text('Create Task', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
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
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
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
      Navigator.pop(context);
    }
  }

  // Helper for consistent border radius
  static RoundedRectangleBorder _roundedRectangleCircular(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
}
