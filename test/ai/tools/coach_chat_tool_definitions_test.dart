import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_definitions.dart';

void main() {
  test('CoachChatToolDefinitions exposes the expected tool names', () {
    final names = CoachChatToolDefinitions.tools
        .map((tool) {
          final function = tool['function'];
          if (function is! Map) return null;
          return function['name']?.toString();
        })
        .whereType<String>()
        .toSet();

    expect(
      names,
      containsAll(<String>[
        'get_today_workout',
        'get_nutrition_today',
        'get_weight_trend',
        'get_muscle_heatmap',
        'get_recovery_status',
      ]),
    );
  });

  test('encodeToolResult serializes maps', () {
    final encoded = CoachChatToolDefinitions.encodeToolResult(
      <String, Object?>{'ok': true, 'calories': 1800},
    );
    expect(encoded, contains('1800'));
    expect(encoded, contains('ok'));
  });
}
