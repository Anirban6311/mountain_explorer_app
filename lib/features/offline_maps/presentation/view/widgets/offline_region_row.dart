import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../domain/entities/offline_region.dart';

class OfflineRegionRow extends StatelessWidget {
  const OfflineRegionRow({
    super.key,
    required this.region,
    required this.onResume,
    required this.onDelete,
  });

  final OfflineRegion region;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  String _formatSize(int bytes) {
    final mb = bytes / 1024 / 1024;
    if (mb < 1) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  ({String label, Color color}) _statusBadge() {
    switch (region.status) {
      case OfflineRegionStatus.complete:
        return (label: 'Complete', color: AppColors.success);
      case OfflineRegionStatus.downloading:
        return (label: 'Downloading', color: AppColors.primary);
      case OfflineRegionStatus.partial:
        return (label: 'Paused', color: AppColors.secondary);
      case OfflineRegionStatus.failed:
        return (label: 'Failed', color: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge();
    final canResume = region.status == OfflineRegionStatus.partial ||
        region.status == OfflineRegionStatus.failed;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Zoom ${region.minZoom}–${region.maxZoom} · '
                        '${_formatSize(region.sizeBytes)} · '
                        '${_formatDate(region.downloadedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.slate600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: badge.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(color: badge.color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canResume)
                  TextButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
