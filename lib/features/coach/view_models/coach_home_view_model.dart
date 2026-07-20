import 'package:flutter/foundation.dart';
import 'package:gymaipro/features/coach/application/coach_facade.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

/// ViewModel for CoachHomeScreen.
class CoachHomeViewModel extends ChangeNotifier {
  CoachHomeViewModel({
    CoachFacade? facade,
    CoachHomeState initialState = const CoachHomeState.loading(),
  }) : _facade = facade,
       _state = initialState;

  final CoachFacade? _facade;
  CoachHomeState _state;
  bool _loaded = false;
  bool _isDisposed = false;
  int _fetchToken = 0;

  CoachHomeState get state => _state;

  @override
  void dispose() {
    _isDisposed = true;
    _fetchToken++;
    super.dispose();
  }

  Future<void> load() async {
    if (_loaded || _isDisposed) return;
    _loaded = true;
    await _fetch();
  }

  Future<void> refresh() async {
    if (_isDisposed) return;
    _loaded = false;
    await load();
  }

  Future<CoachQuickActionResult> runQuickAction(CoachQuickAction action) async {
    if (_isDisposed) {
      return const CoachQuickActionResult(message: '');
    }
    if (action.id == 'review_program' || action.id == 'review') {
      ProductAnalytics.track(ProductAnalyticsEvent.reviewUsed);
    } else if (action.id == 'modify_program' || action.id == 'modify') {
      ProductAnalytics.track(ProductAnalyticsEvent.modifyUsed);
    }
    final result = await (_facade ?? CoachFacade()).runQuickAction(action.id);
    if (_isDisposed) return result;
    _setState(
      _state.copyWith(
        explainability: CoachExplainabilityItem(
          question: ProductCopy.mySuggestion,
          reasons: <String>[result.message],
        ),
      ),
    );
    return result;
  }

  Future<void> _fetch() async {
    if (_isDisposed) return;
    final token = ++_fetchToken;
    _setState(const CoachHomeState.loading());
    try {
      final result = await (_facade ?? CoachFacade()).load();
      if (_isDisposed || token != _fetchToken) return;
      ProductAnalytics.track(ProductAnalyticsEvent.coachHomeOpened);
      _setState(result.state);
    } on Object catch (error) {
      if (_isDisposed || token != _fetchToken) return;
      _setState(CoachHomeState.error(error.toString()));
    }
  }

  void _setState(CoachHomeState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }
}
