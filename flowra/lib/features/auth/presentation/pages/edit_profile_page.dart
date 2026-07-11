import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_picker_sheet.dart';
import '../../domain/entities/user.dart';
import '../bloc/bloc/auth_bloc.dart';
import '../bloc/profile/profile_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

/// Full profile & preferences editor. Provided its own [ProfileBloc] so saving
/// never disturbs the root auth gate.
class EditProfilePage extends StatelessWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>(),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final User user;
  const _EditProfileView({required this.user});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  static const _genders = ['male', 'female', 'other'];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  String? _gender;
  String? _pickedImagePath;
  late TimeOfDay? _workStart;
  late TimeOfDay? _workEnd;
  late Set<int> _restDays;
  late bool _focusModeEnabled;
  late List<String> _blockedApps;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u.fullName);
    _gender = _genders.contains(u.gender) ? u.gender : null;
    _workStart = _parseTime(u.workDayStart);
    _workEnd = _parseTime(u.workDayEnd);
    _restDays = u.restDays.toSet();
    _focusModeEnabled = u.focusModeEnabled;
    _blockedApps = [...u.blockedApps];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _pickedImagePath = file.path);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial =
        (isStart ? _workStart : _workEnd) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _workStart = picked;
        } else {
          _workEnd = picked;
        }
      });
    }
  }

  Future<void> _openAppPicker() async {
    final result = await showAppPickerSheet(context, selected: _blockedApps);
    if (result != null) {
      setState(() => _blockedApps = result);
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updated = User(
      id: widget.user.id,
      fullName: _nameController.text.trim(),
      email: widget.user.email,
      gender: _gender ?? widget.user.gender,
      profilePictureUrl: widget.user.profilePictureUrl,
      restDays: (_restDays.toList()..sort()),
      workDayStart: _workStart != null ? _formatTime(_workStart!) : '',
      workDayEnd: _workEnd != null ? _formatTime(_workEnd!) : '',
      blockedApps: _blockedApps,
      focusModeEnabled: _focusModeEnabled,
      createdAt: widget.user.createdAt,
    );

    context
        .read<ProfileBloc>()
        .add(UpdateProfileSubmitted(updated, imagePath: _pickedImagePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.getTextPrimary(context),
        title: const Text('Edit Profile'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSaved) {
            // Keep the cached auth session's user in sync.
            context.read<AuthBloc>().add(ProfileUpdated(state.user));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is ProfileSaving;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatarPicker()),
                    const SizedBox(height: 28),

                    _sectionLabel('Full Name'),
                    AuthTextField(
                      controller: _nameController,
                      hintText: 'Full name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel('Gender'),
                    _buildGenderSelector(),
                    const SizedBox(height: 20),

                    _sectionLabel('Work Hours'),
                    _buildWorkHours(),
                    const SizedBox(height: 20),

                    _sectionLabel('Rest Days'),
                    _buildRestDays(),
                    const SizedBox(height: 20),

                    _sectionLabel('Focus Mode'),
                    _buildFocusToggle(),
                    const SizedBox(height: 12),

                    _sectionLabel('Blocked Apps'),
                    _buildBlockedApps(),
                    const SizedBox(height: 32),

                    AuthButton(
                      text: 'Save Changes',
                      isLoading: isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildAvatarPicker() {
    final hasPicked = _pickedImagePath != null;
    final hasRemote = widget.user.profilePictureUrl.isNotEmpty;

    ImageProvider? image;
    if (hasPicked) {
      image = FileImage(File(_pickedImagePath!));
    } else if (hasRemote) {
      image = NetworkImage(widget.user.profilePictureUrl);
    }

    return Stack(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: image == null ? AppColors.primaryGradient : null,
            image: image != null
                ? DecorationImage(image: image, fit: BoxFit.cover)
                : null,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: image == null
              ? Text(
                  widget.user.fullName.trim().isNotEmpty
                      ? widget.user.fullName.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getBackground(context),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: _genders.map((g) {
        final selected = _gender == g;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  g[0].toUpperCase() + g.substring(1),
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.getTextSecondary(context),
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkHours() {
    return Row(
      children: [
        Expanded(child: _timeField('Start', _workStart, () => _pickTime(true))),
        const SizedBox(width: 12),
        Expanded(child: _timeField('End', _workEnd, () => _pickTime(false))),
      ],
    );
  }

  Widget _timeField(String label, TimeOfDay? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value != null ? _formatTime(value) : '--:--',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDays() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final selected = _restDays.contains(i);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _restDays.remove(i);
            } else {
              _restDays.add(i);
            }
          }),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : AppColors.getSurface(context),
            ),
            child: Text(
              _weekdays[i],
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFocusToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Enable focus mode',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Block distracting apps during work hours',
          style: TextStyle(
            color: AppColors.getTextSecondary(context),
            fontSize: 12,
          ),
        ),
        value: _focusModeEnabled,
        activeColor: AppColors.secondary,
        onChanged: (v) => setState(() => _focusModeEnabled = v),
      ),
    );
  }

  Widget _buildBlockedApps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_blockedApps.isEmpty)
          Text(
            'No apps selected yet.',
            style: TextStyle(
              color: AppColors.getTextSecondary(context),
              fontSize: 13,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _blockedApps.map((app) {
              return Chip(
                label: Text(app),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                labelStyle:
                    TextStyle(color: AppColors.getTextPrimary(context)),
                deleteIcon: const Icon(Icons.close, size: 18),
                deleteIconColor: AppColors.error,
                onDeleted: () => setState(() => _blockedApps.remove(app)),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openAppPicker,
          icon: const Icon(Icons.playlist_add_check, size: 18),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          label: const Text('Choose apps'),
        ),
      ],
    );
  }
}
