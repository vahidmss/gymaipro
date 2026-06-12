import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/app_access_control_service.dart';

/// آیا چت GPT برای کاربر فعال است؟
bool isGymAiChatAvailable([AppAccessConfig? access]) {
  final cfg = access ?? AppAccessControlService.instance.configNotifier.value;
  if (!cfg.aiChatEnabled) return false;
  return AiEngineConfig.canAttemptOpenAi;
}

String gymAiChatUnavailableMessage([AppAccessConfig? access]) {
  final cfg = access ?? AppAccessControlService.instance.configNotifier.value;
  if (!cfg.aiChatEnabled) {
    final msg = cfg.aiChatUnavailableMessage.trim();
    if (msg.isNotEmpty) return msg;
    return AppConfig.aiChatUnavailableMessage;
  }
  if (!AiEngineConfig.canAttemptOpenAi) {
    return 'اتصال به سرویس هوش مصنوعی برقرار نیست. '
        'OPENAI_USE_PROXY=true یا OPENAI_API_KEY را در .env تنظیم کنید '
        '(یا AI_ENGINE_MODE=openai).';
  }
  return AppConfig.aiChatUnavailableMessage;
}
