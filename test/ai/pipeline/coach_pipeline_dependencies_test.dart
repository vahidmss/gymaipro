import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachPipeline dependency injection', () {
    test('builder source does not construct concrete pipeline services', () {
      final source = File(
        'lib/ai/pipeline/coach_pipeline_builder.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('?? AIContextRepository()')));
      expect(source, isNot(contains('?? CoachBrain(')));
      expect(source, isNot(contains('?? const EntityExtractor()')));
      expect(source, isNot(contains('?? CoachSkillEngine()')));
      expect(source, isNot(contains('?? const PromptBuilder()')));
      expect(
        source,
        contains('required CoachPipelineDependencies dependencies'),
      );
    });
  });
}
