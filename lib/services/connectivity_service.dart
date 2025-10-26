import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connectivity across the app.
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _isConnectedController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _lastConnected = false;

  /// Emits true when device appears to have a network, false otherwise.
  Stream<bool> get isConnectedStream => _isConnectedController.stream;

  Future<void> initialize() async {
    // Emit initial status
    final initial = await _connectivity.checkConnectivity();
    _lastConnected = _hasNetwork(initial);
    _isConnectedController.add(_lastConnected);

    // Listen to changes
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _lastConnected = _hasNetwork(results);
      _isConnectedController.add(_lastConnected);
    });
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _isConnectedController.close();
  }

  /// Returns last known connectivity status.
  bool get isConnected => _lastConnected;

  /// Checks connectivity now and updates last known status.
  Future<bool> checkNow() async {
    final current = await _connectivity.checkConnectivity();
    _lastConnected = _hasNetwork(current);
    return _lastConnected;
  }
}
