import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/env/env.dart';
import '../../../../core/services/offline_tile_store.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../../trek/presentation/cubit/trek_cubit.dart';
import '../../../trek/presentation/view/widgets/trek_toggle_button.dart';
import '../../domain/constants.dart';
import '../cubit/offline_maps_cubit.dart';
import '../cubit/offline_maps_state.dart';
import 'widgets/demo_region_prompt_dialog.dart';
import 'widgets/download_progress_dialog.dart';
import 'widgets/offline_badge.dart';

/// Index of the Map tab in `HomeShell`'s bottom navigation. Keep in sync
/// with `home_shell.dart`'s `IndexedStack` children order.
const int _mapTabIndex = 2;

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  State<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends State<OfflineMapsPage> {
  final MapController _mapController = MapController();
  late final Env _env = getIt<Env>();
  late final OfflineTileStore _tileStore = getIt<OfflineTileStore>();

  bool _onVisibleFired = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OfflineMapsCubit>().attachMapController(_mapController);
      _maybeFireOnVisible();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Calls [OfflineMapsCubit.onMapVisible] the first time this page becomes
  /// the active tab. Without this guard, `IndexedStack` would trigger the
  /// Kangchenjunga prompt on HomeShell mount — before the user has ever
  /// opened the Map tab.
  void _maybeFireOnVisible() {
    if (_onVisibleFired || !mounted) return;
    // Root route deep-links (pushed via /map) don't live inside
    // HomeShell — in that case no HomeCubit is in the tree and we fire
    // immediately. Inside HomeShell, we only fire when Map is the active
    // tab to avoid prompting the user before they've opened Map.
    int? tabIndex;
    try {
      tabIndex = BlocProvider.of<HomeCubit>(context, listen: false)
          .state
          .tabIndex;
    } catch (_) {
      // No HomeCubit in the tree (deep-link path, or test harness).
      tabIndex = null;
    }
    if (tabIndex == null || tabIndex == _mapTabIndex) {
      _onVisibleFired = true;
      context.read<OfflineMapsCubit>().onMapVisible();
    }
  }

  void _onDownloadThisView() {
    final camera = _mapController.camera;
    final bbox = camera.visibleBounds;
    context
        .read<OfflineMapsCubit>()
        .startDownloadOfViewport(bbox, camera.zoom.round());
  }

  Future<void> _handleStateChange(
    BuildContext context,
    OfflineMapsState state,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (state) {
      case MapShowDemoPrompt():
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DemoRegionPromptDialog(),
        );
        if (!context.mounted) return;
        final cubit = context.read<OfflineMapsCubit>();
        if (accepted == true) {
          await cubit.acceptDemoRegion();
        } else {
          await cubit.skipDemoRegion();
        }
      case MapDownloading(:final progress):
        if (!_dialogOpen) {
          _dialogOpen = true;
          final cubit = context.read<OfflineMapsCubit>();
          final initial = progress;
          unawaited(
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              useRootNavigator: false,
              // showDialog pushes a new route — Provider scope from the
              // page does NOT bleed into the dialog's widget tree. Re-
              // expose the page's OfflineMapsCubit instance via .value
              // so the BlocListener + BlocBuilder below can resolve it.
              builder: (dialogCtx) => BlocProvider<OfflineMapsCubit>.value(
                value: cubit,
                child: BlocListener<OfflineMapsCubit, OfflineMapsState>(
                  listenWhen: (prev, curr) =>
                      prev is MapDownloading && curr is! MapDownloading,
                  listener: (_, __) {
                    if (Navigator.of(dialogCtx).canPop()) {
                      Navigator.of(dialogCtx).pop();
                    }
                  },
                  child: BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
                    builder: (_, s) {
                      final current =
                          s is MapDownloading ? s.progress : initial;
                      return DownloadProgressDialog(
                        progress: current,
                        onCancel: cubit.cancelActiveDownload,
                      );
                    },
                  ),
                ),
              ),
            ).then((_) => _dialogOpen = false),
          );
        }
      case MapQuotaExceeded(:final neededBytes, :final quotaBytes):
        final neededMb = (neededBytes / 1024 / 1024).ceil();
        final quotaMb = (quotaBytes / 1024 / 1024).round();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Over quota: needs $neededMb MB, $quotaMb MB allowed.',
            ),
          ),
        );
      case MapError(:final message):
        messenger.showSnackBar(SnackBar(content: Text(message)));
      case MapInitial():
      case MapReady():
        break;
    }
  }

  bool _hasHomeCubit(BuildContext context) {
    try {
      BlocProvider.of<HomeCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapConsumer = BlocConsumer<OfflineMapsCubit, OfflineMapsState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Map'),
            actions: [
              if (!state.isOnline) const OfflineBadge(),
              const TrekToggleButton(),
            ],
          ),
          body: FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(27.69, 88.15),
              initialZoom: 12,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: _env.osmTileUrlTemplate,
                additionalOptions: {'apiKey': _env.maptilerApiKey},
                userAgentPackageName: kTileUserAgent,
                tileProvider: _tileStore.browseTileProvider(
                  storeName: kBrowseStoreName,
                  userAgentPackageName: kTileUserAgent,
                ),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(_env.osmTileAttribution),
                ],
              ),
            ],
          ),
          floatingActionButton: state is MapDownloading
              ? null
              : FloatingActionButton.extended(
                  // Distinct heroTag so this FAB doesn't collide with the
                  // global SosFab overlaid by HomeShell on the Map tab.
                  heroTag: 'offline_maps_download_fab',
                  onPressed: _onDownloadThisView,
                  icon: const Icon(Icons.download),
                  label: const Text('Download this view'),
                ),
          // Move the Map's FAB to the bottom-left so the global SosFab
          // (in HomeShell, anchored bottom-right) doesn't sit on top of
          // it. Both stay reachable; SOS keeps the conventional
          // bottom-right slot.
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        );
      },
    );

    // Provide the singleton `TrekCubit` so the AppBar's `TrekToggleButton`
    // can read state. `.value` so the cubit is not closed when the page
    // unmounts (Iter 5a singleton lifecycle, mirrors `SosCubit`).
    final wrapped = BlocProvider<TrekCubit>.value(
      value: getIt<TrekCubit>(),
      child: mapConsumer,
    );
    if (!_hasHomeCubit(context)) return wrapped;
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (prev, curr) =>
          prev.tabIndex != curr.tabIndex && curr.tabIndex == _mapTabIndex,
      listener: (_, __) => _maybeFireOnVisible(),
      child: wrapped,
    );
  }
}

