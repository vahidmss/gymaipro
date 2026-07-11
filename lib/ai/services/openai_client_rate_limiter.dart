import 'package:gymaipro/ai/services/openai_service.dart';

/// محدودیت نرخ درخواست OpenAI از کلاینت (جلوگیری از سوءاستفاده و هزینهٔ ناگهانی).
class OpenAiClientRateLimiter {
  OpenAiClientRateLimiter._();

  static final OpenAiClientRateLimiter instance = OpenAiClientRateLimiter._();

  static const int maxRequestsPerMinute = 20;
  static const Duration minInterval = Duration(seconds: 2);

  DateTime? _lastRequestAt;
  final List<DateTime> _window = [];

  Future<void> acquire() async {
    final now = DateTime.now();

    if (_lastRequestAt != null) {
      final sinceLast = now.difference(_lastRequestAt!);
      if (sinceLast < minInterval) {
        await Future<void>.delayed(minInterval - sinceLast);
      }
    }

    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _window.removeWhere((t) => t.isBefore(cutoff));

    if (_window.length >= maxRequestsPerMinute) {
      throw const OpenAIException(
        'تعداد درخواست‌های هوش مصنوعی در دقیقهٔ اخیر زیاد است. '
        'لطفاً کمی صبر کنید و دوباره تلاش کنید.',
      );
    }

    _lastRequestAt = DateTime.now();
    _window.add(_lastRequestAt!);
  }
}
