import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:http/http.dart' as http;

/// Service to monitor internet connectivity across the app.
///
/// [checkNow] and [isConnectedStream] work even before [initialize] is called,
/// so they can be used during the bootstrap/splash phase.
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _isConnectedController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _isVpnController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _initialized = false;

  bool _lastConnected = false;
  bool _lastVpn = false;

  /// Emits true when device appears to have a network, false otherwise.
  Stream<bool> get isConnectedStream => _isConnectedController.stream;

  /// Emits true when we detect a VPN transport among current connections.
  /// این فقط بر اساس ConnectivityResult.vpn است و ۱۰۰٪ دقیق نیست،
  /// ولی برای نمایش هشدار تجربه بهتر کافی است.
  Stream<bool> get isVpnStream => _isVpnController.stream;

  /// Full initialization — starts the persistent connectivity listener.
  /// Safe to call multiple times (no-op after first call).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Emit initial status
    final initial = await _connectivity.checkConnectivity();
    _updateStates(initial);

    // Listen to changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStates);
  }

  /// Lightweight bootstrap listener — starts emitting connectivity changes
  /// without the full [initialize] overhead. Used during splash phase.
  /// No-op if [initialize] was already called.
  void ensureListening() {
    if (_initialized || _subscription != null) return;
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStates);
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
    _isVpnController.close();
  }

  /// Returns last known connectivity status.
  bool get isConnected => _lastConnected;

  /// آخرین وضعیت تشخیص وی‌پی‌ان (بعد از [checkNow] یا [initialize] معتبر است).
  bool get isVpn => _lastVpn;

  /// Checks connectivity now and updates last known status.
  /// Also emits on [isConnectedStream] if the status changed.
  Future<bool> checkNow() async {
    final current = await _connectivity.checkConnectivity();
    _updateStates(current);
    return _lastConnected;
  }

  /// Lightweight backend reachability check (health endpoint).
  Future<bool> canReachAppBackend() async {
    if (!await checkNow()) return false;
    try {
      final response = await http
          .get(Uri.parse(AppConfig.backendHealthCheckUrl))
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  void _updateStates(List<ConnectivityResult> results) {
    final connected = _hasNetwork(results);
    final vpnActive = results.contains(ConnectivityResult.vpn);

    if (connected != _lastConnected) {
      _lastConnected = connected;
      _isConnectedController.add(_lastConnected);
    }

    if (vpnActive != _lastVpn) {
      _lastVpn = vpnActive;
      _isVpnController.add(_lastVpn);
    }
  }
}
