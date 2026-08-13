import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/bloc/auth_bloc.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static const _genders = ['male', 'female', 'other'];
  String _selectedGender = 'male';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(RegisterRequested(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            gender: _selectedGender,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextPrimary(context)),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Please sign in.'),
                backgroundColor: AppColors.primary,
              ),
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join Flowra and boost your productivity',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Full Name
                      AuthTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      AuthTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      AuthTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender selector
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 4),
                          child: Text(
                            'Gender',
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      _buildGenderSelector(),
                      const SizedBox(height: 28),

                      // Register Button
                      AuthButton(
                        text: 'Create Account',
                        isLoading: isLoading,
                        onPressed: _onRegister,
                      ),
                      const SizedBox(height: 20),

                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: _genders.map((g) {
        final selected = _selectedGender == g;
        final isLast = g == _genders.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGender = g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  g[0].toUpperCase() + g.substring(1),
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.getTextSecondary(context),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
