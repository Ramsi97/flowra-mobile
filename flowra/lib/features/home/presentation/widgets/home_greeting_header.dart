import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/bloc/auth_bloc.dart';

/// Top-of-dashboard greeting: today's date, a time-aware salutation and the
/// user's first name (pulled from [AuthBloc]). Replaces the bare "Flowra"
/// wordmark so Home opens with something personal instead of a logo.
class HomeGreetingHeader extends StatelessWidget {
  /// Optional trailing action (typically a [SettingsButton]).
  final Widget? trailing;

  const HomeGreetingHeader({super.key, this.trailing});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      final name = state.user.fullName.trim();
      if (name.isNotEmpty) return name.split(' ').first;
    }
    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMMM d').format(DateTime.now());
    const nameStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.15,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${_greeting()}, ',
                      style: nameStyle.copyWith(
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Flexible(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          _firstName(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: nameStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const Text('  👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
