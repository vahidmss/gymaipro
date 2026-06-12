import 'package:gymaipro/config/app_config.dart';

/// حالت موتور هوش مصنوعی — پیش‌فرض: OpenAI وقتی پروکسی/کلید موجود است.
enum AiEngineMode {
  /// قوانین علمی + دیتابیس تمرین (پشتیبان وقتی OpenAI در دسترس نیست)
  ruleBased,

  /// OpenAI / پروکسی سرور
  openAi,
}

/// تنظیمات مرکزی موتور AI.
class AiEngineConfig {
  static AiEngineMode get mode {
    const env = String.fromEnvironment('AI_ENGINE_MODE');
    if (env.isNotEmpty) {
      return _parseMode(env);
    }
    final dotenvMode = AppConfig.dotenvValue('AI_ENGINE_MODE');
    if (dotenvMode != null) return _parseMode(dotenvMode);
    if (AppConfig.openaiUseProxy || AppConfig.openaiApiKey.isNotEmpty) {
      return AiEngineMode.openAi;
    }
    return AiEngineMode.ruleBased;
  }

  static bool get useRuleBasedEngine => mode == AiEngineMode.ruleBased;

  static bool get useOpenAiEngine => mode == AiEngineMode.openAi;

  static bool get usesDeviceDirectRoute => AppConfig.aiUsesDeviceDirectRoute;

  static bool get usesServerProxyRoute =>
      AppConfig.openaiUseProxy && AppConfig.supabaseEdgeFunctionsEnabled;

  /// آیا تلاش برای فراخوانی OpenAI مجاز است؟
  static bool get canAttemptOpenAi =>
      useOpenAiEngine &&
      (usesServerProxyRoute || AppConfig.openaiApiKey.isNotEmpty);

  static AiEngineMode _parseMode(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'openai' || v == 'open_ai' || v == 'gpt') {
      return AiEngineMode.openAi;
    }
    return AiEngineMode.ruleBased;
  }
}
