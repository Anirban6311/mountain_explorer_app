import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/comment.dart';

class CommentRow extends StatelessWidget {
  final Comment comment;
  final bool canDelete;
  final VoidCallback? onDelete;

  const CommentRow({
    super.key,
    required this.comment,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = comment.commentedByName.isEmpty
        ? 'Deleted user'
        : comment.commentedByName;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: theme.textTheme.labelLarge),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DateFormat.jm().format(comment.commentedAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              tooltip: 'Delete comment',
            ),
        ],
      ),
    );
  }
}
