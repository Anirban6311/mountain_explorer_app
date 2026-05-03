import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: radius,
      elevation: 1,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: content,
            ),
    );
  }
}
