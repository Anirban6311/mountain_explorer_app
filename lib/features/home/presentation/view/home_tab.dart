import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/home_cubit.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AuthCubit>().state;
    final name = switch (state) {
      Authenticated(:final user) =>
        user.isAnonymous ? 'Guest' : (user.displayName ?? 'there'),
      _ => 'there',
    };
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MountainBanner(name: name),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.0,
                  children: [
                    _DashboardTile(
                      title: 'Browse',
                      subtitle: 'Hill stations & peaks',
                      icon: Icons.terrain,
                      color: AppColors.primary,
                      onTap: () => context.read<HomeCubit>().selectTab(1),
                    ),
                    _DashboardTile(
                      title: 'Search',
                      subtitle: 'Find by name',
                      icon: Icons.search_rounded,
                      color: AppColors.secondary,
                      onTap: () => context.push(Routes.mountainSearch),
                    ),
                    _DashboardTile(
                      title: 'Favourites',
                      subtitle: 'Your saved peaks',
                      icon: Icons.favorite_rounded,
                      color: AppColors.primaryLight,
                      onTap: () => context.push(Routes.likedMountains),
                    ),
                    _DashboardTile(
                      title: 'Checklist',
                      subtitle: 'Pack before the trail',
                      icon: Icons.backpack_rounded,
                      color: AppColors.tertiary,
                      onTap: () => context.push(Routes.checklist),
                    ),
                    _DashboardTile(
                      title: 'Map',
                      subtitle: 'Offline tiles',
                      icon: Icons.map_rounded,
                      color: AppColors.secondaryLight,
                      onTap: () => context.read<HomeCubit>().selectTab(2),
                    ),
                    _DashboardTile(
                      title: 'Community',
                      subtitle: 'Stories from the trail',
                      icon: Icons.forum_rounded,
                      color: AppColors.primaryDark,
                      onTap: () => context.read<HomeCubit>().selectTab(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero banner with a stylised three-ridge mountain silhouette painted
/// natively (no SVG dependency). Greeting text overlays the lower band.
class _MountainBanner extends StatelessWidget {
  const _MountainBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sky-to-meadow gradient backdrop.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE6E2D2), // soft hazy sky
                  AppColors.stone100,
                ],
              ),
            ),
          ),
          // A soft sun/cloud disc in the upper-right.
          const Positioned(
            top: 28,
            right: 36,
            child: _SunDisc(size: 44),
          ),
          // Three layered mountain ridges.
          Positioned.fill(
            child: CustomPaint(
              painter: _MountainPainter(),
            ),
          ),
          // Greeting text overlay — bottom-left, on top of the ridges.
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $name 👋',
                  style: text.headlineSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Where would you like to explore today?',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.92),
                    shadows: const [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SunDisc extends StatelessWidget {
  const _SunDisc({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFFCEFC8), Color(0xFFF1D78C)],
        ),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Three ridges from far-back to near-front, each darker and lower
    // on the canvas so they layer like real mountains.
    final far = Paint()..color = AppColors.primaryLight.withValues(alpha: 0.55);
    final mid = Paint()..color = AppColors.primary.withValues(alpha: 0.85);
    final near = Paint()..color = AppColors.primaryDark;

    // Far ridge.
    final farPath = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.18, size.height * 0.30)
      ..lineTo(size.width * 0.32, size.height * 0.45)
      ..lineTo(size.width * 0.48, size.height * 0.20)
      ..lineTo(size.width * 0.62, size.height * 0.42)
      ..lineTo(size.width * 0.78, size.height * 0.28)
      ..lineTo(size.width, size.height * 0.50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farPath, far);

    // Mid ridge.
    final midPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.28, size.height * 0.68)
      ..lineTo(size.width * 0.42, size.height * 0.42)
      ..lineTo(size.width * 0.55, size.height * 0.62)
      ..lineTo(size.width * 0.70, size.height * 0.50)
      ..lineTo(size.width * 0.86, size.height * 0.65)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(midPath, mid);

    // Near ridge — darkest, foreground.
    final nearPath = Path()
      ..moveTo(0, size.height * 0.92)
      ..lineTo(size.width * 0.08, size.height * 0.78)
      ..lineTo(size.width * 0.22, size.height * 0.85)
      ..lineTo(size.width * 0.38, size.height * 0.65)
      ..lineTo(size.width * 0.52, size.height * 0.80)
      ..lineTo(size.width * 0.68, size.height * 0.72)
      ..lineTo(size.width * 0.84, size.height * 0.86)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(nearPath, near);

    // A few tiny snow caps on the near ridge peaks.
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.85);
    void cap(Offset peak, double w) {
      final cp = Path()
        ..moveTo(peak.dx - w, peak.dy + w * 0.7)
        ..lineTo(peak.dx, peak.dy)
        ..lineTo(peak.dx + w, peak.dy + w * 0.7)
        ..close();
      canvas.drawPath(cp, snow);
    }

    cap(Offset(size.width * 0.38, size.height * 0.65), 9);
    cap(Offset(size.width * 0.68, size.height * 0.72), 7);
  }

  @override
  bool shouldRepaint(covariant _MountainPainter oldDelegate) => false;
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Subtle ridge silhouette in the lower-right of every tile so
            // each box echoes the hero banner's mountain motif.
            Positioned.fill(
              child: CustomPaint(
                painter: _TileRidgePainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _TileRidgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.30, size.height * 0.78)
      ..lineTo(size.width * 0.50, size.height * 0.90)
      ..lineTo(size.width * 0.72, size.height * 0.65)
      ..lineTo(size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TileRidgePainter oldDelegate) => false;
}
