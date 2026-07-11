import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A branded, centered loading indicator used across the app instead of a bare
/// [CircularProgressIndicator]. Shows a soft glowing accent ring with an
/// optional label so long loads feel intentional rather than broken.
class AppLoader extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoader({super.key, this.message, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              backgroundColor: AppColors.primary.withOpacity(0.15),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextSecondary(context),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A full-screen dimmed + blurred scrim with a centered [AppLoader], used as an
/// overlay while a mutation is in flight and the underlying content stays
/// visible.
class AppLoaderOverlay extends StatelessWidget {
  final String? message;

  const AppLoaderOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withOpacity(0.35),
        child: AppLoader(message: message),
      ),
    );
  }
}
