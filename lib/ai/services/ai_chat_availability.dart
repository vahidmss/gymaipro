import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/app_access_control_service.dart';

/// پیام واحد وقتی مدل‌های هوش مصنوعی در دسترس نیستند (ساخت برنامه و مسیرهای AI).
const String gymAiModelsUnavailableMessage =
    'در حال حاضر دسترسی به مدل‌های هوش مصنوعی امکان‌پذیر نیست.';

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
    return gymAiModelsUnavailableMessage;
  }
  return AppConfig.aiChatUnavailableMessage;
}
