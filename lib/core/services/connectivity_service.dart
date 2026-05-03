import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Future<bool> isOnline();

  /// Emits true when any connection is available, false when fully offline.
  Stream<bool> onConnectivityChanged();
}

class ConnectivityPlusConnectivityService implements ConnectivityService {
  ConnectivityPlusConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  @override
  Stream<bool> onConnectivityChanged() =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
