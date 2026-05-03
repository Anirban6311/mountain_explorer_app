import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool isLikedByCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const PostCard({
    super.key,
    required this.post,
    required this.isLikedByCurrentUser,
    this.onTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.pImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.pImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const ColoredBox(color: AppColors.slate200),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.slate400,
                    child: Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(post.pTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            post.pDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                post.uName,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.schedule,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                DateFormat.yMMMd().add_jm().format(post.pTime),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onLike,
                icon: Icon(
                  isLikedByCurrentUser
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isLikedByCurrentUser
                      ? AppColors.error
                      : theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
              Text('${post.likes.length}',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
