import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';

/// Auth-screen primary button — a thin alias over [AppButton] so the login,
/// register and profile forms share the app's single gradient button style
/// (previously this hard-coded its own `#6C63FF` brand colour).
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      onPressed: onPressed,
      loading: isLoading,
    );
  }
}
