import 'dart:convert';

/// OpenAI function-calling schemas for GymAI Coach chat.
///
/// The model may call these when it needs a fresh app-engine snapshot beyond
/// the already-injected context package.
abstract final class CoachChatToolDefinitions {
  static const List<Map<String, Object?>> tools = <Map<String, Object?>>[
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': 'get_today_workout',
        'description':
            'Fetch the user\'s active workout program and today\'s session '
            '(selected day, exercise list, whether today is already logged).',
        'parameters': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{},
        },
      },
    },
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': 'get_nutrition_today',
        'description':
            'Fetch daily calorie/macro targets and today\'s logged food intake.',
        'parameters': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{},
        },
      },
    },
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': 'get_weight_trend',
        'description':
            'Fetch recent weigh-ins, latest weight, and short-term weight trend.',
        'parameters': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{},
        },
      },
    },
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': 'get_muscle_heatmap',
        'description':
            'Fetch this week\'s muscle stimulus heatmap and coach insight lines.',
        'parameters': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{},
        },
      },
    },
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': 'get_recovery_status',
        'description':
            'Fetch recovery/readiness score and days since last logged workout.',
        'parameters': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{},
        },
      },
    },
  ];

  static String encodeToolResult(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return jsonEncode(<String, Object?>{'ok': false, 'error': 'encode_failed'});
    }
  }
}
