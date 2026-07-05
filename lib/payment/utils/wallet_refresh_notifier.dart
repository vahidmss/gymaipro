import 'dart:async';

class WalletRefreshSignal {
  const WalletRefreshSignal({this.balanceAlreadyRefreshed = false});

  /// When true, listeners should reload UI from cache without another network refresh.
  final bool balanceAlreadyRefreshed;
}

/// سیگنال سبک برای تازه‌سازی UI کیف پول بعد از شارژ آنلاین.
final class WalletRefreshNotifier {
  static final Set<void Function(WalletRefreshSignal)> _listeners = {};
  static Timer? _debounceTimer;
  static WalletRefreshSignal _pendingSignal = const WalletRefreshSignal();

  static void listen(void Function(WalletRefreshSignal) listener) {
    _listeners.add(listener);
  }

  static void unlisten(void Function(WalletRefreshSignal) listener) {
    _listeners.remove(listener);
  }

  static void notifyRefresh({bool balanceAlreadyRefreshed = false}) {
    _pendingSignal = WalletRefreshSignal(
      balanceAlreadyRefreshed:
          balanceAlreadyRefreshed || _pendingSignal.balanceAlreadyRefreshed,
    );
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      final signal = _pendingSignal;
      _pendingSignal = const WalletRefreshSignal();
      for (final listener in List<void Function(WalletRefreshSignal)>.from(
        _listeners,
      )) {
        listener(signal);
      }
    });
  }
}
