import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(Icons.wifi_off, size: 16, color: Colors.white),
        label: Text('Offline', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.slate700,
      ),
    );
  }
}
