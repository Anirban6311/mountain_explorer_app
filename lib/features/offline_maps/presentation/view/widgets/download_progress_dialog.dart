import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/download_progress.dart';

class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  final DownloadProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final pct = progress.tilesTotal == 0
        ? 0.0
        : (progress.tilesDone / progress.tilesTotal).clamp(0.0, 1.0);
    final mb = (progress.bytesDone / (1024 * 1024)).toStringAsFixed(1);

    return AlertDialog(
      title: const Text('Downloading tiles'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: pct),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${progress.tilesDone} of ${progress.tilesTotal} tiles · $mb MB',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
