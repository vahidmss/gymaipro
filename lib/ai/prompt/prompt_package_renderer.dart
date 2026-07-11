import 'dart:convert';

import 'package:gymaipro/ai/prompt/prompt_package.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';

/// Renders a prompt package into a system prompt string for OpenAI.
///
/// This renderer does not modify the existing OpenAI service. It only converts
/// the v2 prompt package into text when the Coach v2 feature flag is enabled.
class PromptPackageRenderer {
  const PromptPackageRenderer._();

  /// Renders [package] as a Coach v2 system prompt.
  static String render(PromptPackage package) {
    final buffer = StringBuffer()
      ..writeln('شما ${package.personality.title} هستید.')
      ..writeln(package.personality.description)
      ..writeln('همیشه فارسی پاسخ دهید و فقط در حوزه فیتنس و تغذیه کمک کنید.')
      ..writeln();

    for (final section in package.sections) {
      buffer
        ..writeln('## ${section.title}')
        ..writeln(_formatContent(section))
        ..writeln();
    }

    buffer.writeln(
      'قوانین: برنامه کامل تمرینی ننویسید مگر کاربر اصرار کند. '
      'ایمنی کاربر اولویت دارد.',
    );

    return buffer.toString().trim();
  }

  static String _formatContent(PromptSection section) {
    final content = section.content;
    if (content is String) return content;
    if (content is Map || content is List) {
      return const JsonEncoder.withIndent('  ').convert(content);
    }
    return content.toString();
  }
}
