import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../weather/domain/entities/weather.dart';
import '../../domain/entities/mountain.dart';

class MountainCard extends StatelessWidget {
  final Mountain mountain;
  final Weather? weather;
  final bool isLiked;
  final bool likeEnabled;
  final VoidCallback? onLikeTap;

  /// Optional long-press handler. The page passes a callback that opens
  /// the action menu (Download area / View on map). Iter 3 only wires
  /// this on the main mountain list — `LikedMountainsPage` etc. can
  /// reuse it without reshaping the card.
  final VoidCallback? onLongPress;

  const MountainCard({
    super.key,
    required this.mountain,
    required this.isLiked,
    this.weather,
    this.likeEnabled = true,
    this.onLikeTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mountain.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: mountain.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const ColoredBox(color: AppColors.slate200),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: AppColors.slate400,
                child: Center(child: Icon(Icons.broken_image, size: 40)),
              ),
            )
          else
            const ColoredBox(color: AppColors.slate400),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _WeatherChip(weather: weather),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mountain.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        mountain.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: likeEnabled
                      ? (isLiked ? 'Remove from favourites' : 'Save to favourites')
                      : 'Sign up to save favourites',
                  child: IconButton(
                    onPressed: likeEnabled ? onLikeTap : null,
                    iconSize: 32,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.error : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final Weather? weather;
  const _WeatherChip({this.weather});

  @override
  Widget build(BuildContext context) {
    final w = weather;
    if (w == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_outlined, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${w.temperatureC.round()}°C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
