import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../cubit/offline_maps_cubit.dart';
import '../cubit/offline_maps_state.dart';
import 'widgets/offline_region_row.dart';

class OfflineRegionsCatalogPage extends StatelessWidget {
  const OfflineRegionsCatalogPage({super.key});

  /// The page expects an `OfflineMapsCubit` to already be provided by the
  /// route handler (see `_withOfflineMapsCubit` in `app_router.dart`). The
  /// catalog never creates its own cubit — that would race with HomeShell's
  /// instance and leak streams.
  @override
  Widget build(BuildContext context) => const _CatalogView();
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  Future<void> _confirmDelete(
    BuildContext context,
    String regionId,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete region?'),
        content: Text(
          'This removes "$name" from the list. Cached map tiles stay in '
          'the shared cache; use "Reset entire cache" to free disk space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<OfflineMapsCubit>().deleteRegion(regionId);
    }
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset entire cache?'),
        content: const Text(
          'This deletes every cached map tile and clears every region '
          'from the catalog. Any active download will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<OfflineMapsCubit>().resetEntireCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline regions'),
        actions: [
          IconButton(
            tooltip: 'Reset entire cache',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmResetAll(context),
          ),
        ],
      ),
      body: BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
        builder: (context, state) {
          if (state.regions.isEmpty) {
            return const EmptyState(
              icon: Icons.layers_outlined,
              message:
                  'No offline regions yet. Open the Map tab and use\n'
                  '"Download this view" to cache an area for offline use.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.regions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final region = state.regions[i];
              return OfflineRegionRow(
                region: region,
                onResume: () => context
                    .read<OfflineMapsCubit>()
                    .resumeDownload(region.id),
                onDelete: () =>
                    _confirmDelete(context, region.id, region.name),
              );
            },
          );
        },
      ),
    );
  }
}
