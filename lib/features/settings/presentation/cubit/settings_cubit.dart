import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../../offline_maps/domain/entities/offline_region.dart';
import '../../../offline_maps/domain/usecases/total_size_bytes.dart';
import '../../../offline_maps/domain/usecases/watch_regions.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required AppPrefs prefs,
    required TotalSizeBytes totalSizeBytes,
    required WatchRegions watchRegions,
  })  : _prefs = prefs,
        _total = totalSizeBytes,
        _watch = watchRegions,
        super(const SettingsState()) {
    // Refresh total usage whenever the regions table mutates.
    _regionsSub = _watch().listen((_) => _refreshUsage());
  }

  static const int minQuotaMb = 50;
  static const int maxQuotaMb = 1000;

  final AppPrefs _prefs;
  final TotalSizeBytes _total;
  final WatchRegions _watch;
  StreamSubscription<List<OfflineRegion>>? _regionsSub;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    final usage = await _total();
    final used = switch (usage) {
      Success<int>(:final value) => value,
      Failure<int>() => 0,
    };
    emit(state.copyWith(
      quotaMb: _prefs.getQuotaMb(),
      totalUsedBytes: used,
      loading: false,
    ));
  }

  Future<void> setQuota(int mb) async {
    final clamped = math.max(minQuotaMb, math.min(maxQuotaMb, mb));
    await _prefs.setQuotaMb(clamped);
    emit(state.copyWith(quotaMb: clamped));
  }

  /// Updates the slider's visual value without persisting to disk. Used
  /// while the user is dragging; `setQuota` is called on release.
  void previewQuota(int mb) {
    if (isClosed) return;
    final clamped = math.max(minQuotaMb, math.min(maxQuotaMb, mb));
    emit(state.copyWith(quotaMb: clamped));
  }

  Future<void> _refreshUsage() async {
    if (isClosed) return;
    final usage = await _total();
    if (isClosed) return;
    final used = switch (usage) {
      Success<int>(:final value) => value,
      Failure<int>() => state.totalUsedBytes,
    };
    emit(state.copyWith(totalUsedBytes: used));
  }

  @override
  Future<void> close() async {
    await _regionsSub?.cancel();
    return super.close();
  }
}
