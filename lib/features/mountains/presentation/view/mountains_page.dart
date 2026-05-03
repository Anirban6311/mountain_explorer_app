import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../offline_maps/presentation/cubit/offline_maps_cubit.dart';
import '../../domain/entities/mountain.dart';
import '../cubit/mountains_cubit.dart';
import '../cubit/mountains_state.dart';
import '../widgets/mountain_card.dart';

/// Assumes a `MountainsCubit` is provided up-tree (by `HomeShell` or by a
/// standalone route that wraps this page in a `BlocProvider`).
class MountainsPage extends StatelessWidget {
  const MountainsPage({super.key});

  @override
  Widget build(BuildContext context) => const _MountainsView();
}

class _MountainsView extends StatelessWidget {
  const _MountainsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(
        title: 'Mountains',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.mountainSearch),
          ),
        ],
      ),
      body: BlocBuilder<MountainsCubit, MountainsState>(
        builder: (context, state) {
          return switch (state) {
            MountainsInitial() || MountainsLoading() =>
              const Center(child: CircularProgressIndicator()),
            MountainsError(:final message) => ErrorView(
                message: message,
                onRetry: () {
                  final uid = _uidOr(context, '');
                  context.read<MountainsCubit>().load(uid: uid);
                },
              ),
            MountainsLoaded() => state.mountains.isEmpty
                ? const EmptyState(
                    message: 'No mountains available yet.',
                    icon: Icons.landscape_outlined,
                  )
                : _Carousel(state: state),
          };
        },
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  final MountainsLoaded state;
  const _Carousel({required this.state});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.height * 0.62).clamp(360.0, 620.0);
    final authState = context.watch<AuthCubit>().state;
    final uid = _uidOr(context, '');
    final isAnonymous = switch (authState) {
      Authenticated(:final user) => user.isAnonymous,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: CarouselSlider.builder(
        itemCount: state.mountains.length,
        itemBuilder: (context, index, _) {
          final mountain = state.mountains[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: MountainCard(
              mountain: mountain,
              isLiked: state.likedIds.contains(mountain.id),
              weather: state.weatherByCity[mountain.name],
              likeEnabled: !isAnonymous && uid.isNotEmpty,
              onLikeTap: () => context
                  .read<MountainsCubit>()
                  .toggleLike(uid: uid, mountainId: mountain.id),
              onLongPress: () => _showMountainActions(context, mountain),
            ),
          );
        },
        options: CarouselOptions(
          height: cardHeight,
          viewportFraction: 0.86,
          enlargeCenterPage: true,
          enlargeFactor: 0.18,
        ),
      ),
    );
  }
}

String _uidOr(BuildContext context, String fallback) {
  final state = context.read<AuthCubit>().state;
  return switch (state) {
    Authenticated(:final user) => user.uid,
    NeedsVerification(:final user) => user.uid,
    _ => fallback,
  };
}

/// Opens a bottom sheet with map-related actions for [mountain].
///
/// "Download area" appears only when the mountain has coordinates;
/// otherwise the user only sees "View on map" (which simply switches to
/// the Map tab without re-centering).
Future<void> _showMountainActions(
  BuildContext context,
  Mountain mountain,
) async {
  final hasCoords = mountain.hasCoordinates;
  // Look up cubits BEFORE awaiting on the bottom sheet so we don't reuse
  // a `BuildContext` across the async gap.
  HomeCubit? homeCubit;
  OfflineMapsCubit? mapsCubit;
  try {
    homeCubit = BlocProvider.of<HomeCubit>(context, listen: false);
  } catch (_) {}
  try {
    mapsCubit = BlocProvider.of<OfflineMapsCubit>(context, listen: false);
  } catch (_) {}

  final action = await showModalBottomSheet<_MountainAction>(
    context: context,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('View on map'),
            onTap: () =>
                Navigator.of(sheetCtx).pop(_MountainAction.viewOnMap),
          ),
          if (hasCoords)
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download area'),
              subtitle:
                  const Text('Caches a 10 km square around this mountain'),
              onTap: () =>
                  Navigator.of(sheetCtx).pop(_MountainAction.downloadArea),
            )
          else
            const ListTile(
              leading: Icon(Icons.info_outline),
              enabled: false,
              title: Text('Download area unavailable'),
              subtitle: Text('No coordinates recorded for this mountain.'),
            ),
        ],
      ),
    ),
  );

  if (action == null) return;
  // Switch to the Map tab regardless of which action was chosen.
  homeCubit?.selectTab(2);
  if (action == _MountainAction.downloadArea && hasCoords) {
    await mapsCubit?.startDownloadOfMountain(mountain);
  } else {
    mapsCubit?.centerOnMountain(mountain);
  }
}

enum _MountainAction { viewOnMap, downloadArea }
