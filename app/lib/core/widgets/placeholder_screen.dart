import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Lightweight placeholder for screens not yet built / deferred to V2.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.ink3),
              const SizedBox(height: AppSpacing.s16),
              Text(title, style: t.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s8),
              Text(subtitle,
                  style: t.bodyLarge?.copyWith(color: AppColors.ink2),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
