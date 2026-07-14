import 'package:gymaipro/ai/entity/entity_definition.dart';
import 'package:gymaipro/ai/entity/entity_rule.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';

/// Data-driven registry for entity definitions, synonyms, and regex rules.
class EntityRegistry {
  const EntityRegistry({
    this.definitions = defaultDefinitions,
    this.rules = defaultRules,
  });

  /// Default entity definitions.
  static const Map<EntityType, EntityDefinition> defaultDefinitions =
      <EntityType, EntityDefinition>{
        EntityType.height: EntityDefinition(
          type: EntityType.height,
          id: 'height',
          title: 'Height',
          description: 'User height.',
          valueKind: EntityValueKind.number,
          defaultUnit: 'cm',
          supportedUnits: <String>['cm', 'm'],
        ),
        EntityType.weight: EntityDefinition(
          type: EntityType.weight,
          id: 'weight',
          title: 'Weight',
          description: 'User body weight.',
          valueKind: EntityValueKind.number,
          defaultUnit: 'kg',
          supportedUnits: <String>['kg'],
        ),
        EntityType.age: EntityDefinition(
          type: EntityType.age,
          id: 'age',
          title: 'Age',
          description: 'User age.',
          valueKind: EntityValueKind.number,
        ),
        EntityType.gender: EntityDefinition(
          type: EntityType.gender,
          id: 'gender',
          title: 'Gender',
          description: 'User gender.',
          valueKind: EntityValueKind.enumValue,
        ),
        EntityType.goal: EntityDefinition(
          type: EntityType.goal,
          id: 'goal',
          title: 'Goal',
          description: 'Fitness or nutrition goal.',
          valueKind: EntityValueKind.enumValue,
        ),
        EntityType.equipment: EntityDefinition(
          type: EntityType.equipment,
          id: 'equipment',
          title: 'Equipment',
          description: 'Available exercise equipment.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.experience: EntityDefinition(
          type: EntityType.experience,
          id: 'experience',
          title: 'Experience',
          description: 'Training experience level.',
          valueKind: EntityValueKind.enumValue,
        ),
        EntityType.injury: EntityDefinition(
          type: EntityType.injury,
          id: 'injury',
          title: 'Injury',
          description: 'Reported injury.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.medicalCondition: EntityDefinition(
          type: EntityType.medicalCondition,
          id: 'medical_condition',
          title: 'Medical Condition',
          description: 'Medical condition or contraindication.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.muscleGroup: EntityDefinition(
          type: EntityType.muscleGroup,
          id: 'muscle_group',
          title: 'Muscle Group',
          description: 'Target muscle group.',
          valueKind: EntityValueKind.enumValue,
        ),
        EntityType.exerciseName: EntityDefinition(
          type: EntityType.exerciseName,
          id: 'exercise_name',
          title: 'Exercise Name',
          description: 'Exercise name mentioned by user.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.workoutDay: EntityDefinition(
          type: EntityType.workoutDay,
          id: 'workout_day',
          title: 'Workout Day',
          description: 'Workout day reference.',
          valueKind: EntityValueKind.enumValue,
        ),
        EntityType.timeExpression: EntityDefinition(
          type: EntityType.timeExpression,
          id: 'time_expression',
          title: 'Time Expression',
          description: 'Natural time expression.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.supplement: EntityDefinition(
          type: EntityType.supplement,
          id: 'supplement',
          title: 'Supplement',
          description: 'Supplement name.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.food: EntityDefinition(
          type: EntityType.food,
          id: 'food',
          title: 'Food',
          description: 'Food item.',
          valueKind: EntityValueKind.text,
        ),
        EntityType.sleepDuration: EntityDefinition(
          type: EntityType.sleepDuration,
          id: 'sleep_duration',
          title: 'Sleep Duration',
          description: 'Sleep duration.',
          valueKind: EntityValueKind.duration,
          defaultUnit: 'hour',
          supportedUnits: <String>['hour'],
        ),
        EntityType.waterIntake: EntityDefinition(
          type: EntityType.waterIntake,
          id: 'water_intake',
          title: 'Water Intake',
          description: 'Daily water intake.',
          valueKind: EntityValueKind.volume,
          defaultUnit: 'liter',
          supportedUnits: <String>['liter', 'ml'],
        ),
      };

  /// Default extraction rules.
  static const List<EntityRule> defaultRules = <EntityRule>[
    EntityRule(
      id: 'regex_height',
      type: EntityType.height,
      ruleType: EntityRuleType.regex,
      weight: 1.2,
      regexPattern:
          r'(?:قد|height)\s*(?:من)?\s*(\d+(?:[\.,]\d+)?)\s*(cm|سانت|سانتی|متر|m)?',
      unitGroup: 2,
      description: 'Height with optional unit.',
    ),
    EntityRule(
      id: 'regex_weight',
      type: EntityType.weight,
      ruleType: EntityRuleType.regex,
      weight: 1.2,
      regexPattern:
          r'(?:وزن|weight)\s*(?:من)?\s*(\d+(?:[\.,]\d+)?)\s*(kg|کیلو|کیلوگرم)?',
      unitGroup: 2,
      description: 'Weight with optional unit.',
    ),
    EntityRule(
      id: 'regex_age',
      type: EntityType.age,
      ruleType: EntityRuleType.regex,
      weight: 1.1,
      regexPattern: r'(?:سن|age)\s*(?:من)?\s*(\d{1,2})',
      description: 'Age expression.',
    ),
    EntityRule(
      id: 'regex_age_years',
      type: EntityType.age,
      ruleType: EntityRuleType.regex,
      weight: 1,
      regexPattern: r'(\d{1,3})\s*(?:سال|سالم|years?\s*old)',
      description: 'Age with years suffix.',
    ),
    EntityRule(
      id: 'regex_sleep_duration',
      type: EntityType.sleepDuration,
      ruleType: EntityRuleType.regex,
      weight: 1.1,
      regexPattern:
          r'(?:خواب|sleep)\s*(?:من)?\s*(\d+(?:[\.,]\d+)?)\s*(ساعت|hour|hours|h)?',
      unitGroup: 2,
      description: 'Sleep duration in hours.',
    ),
    EntityRule(
      id: 'regex_water_intake',
      type: EntityType.waterIntake,
      ruleType: EntityRuleType.regex,
      weight: 1.1,
      regexPattern:
          r'(?:آب|water)\s*(?:من)?\s*(\d+(?:[\.,]\d+)?)\s*(لیتر|liter|l|ml|میلی لیتر)?',
      unitGroup: 2,
      description: 'Water intake with unit.',
    ),
    EntityRule(
      id: 'keyword_gender',
      type: EntityType.gender,
      ruleType: EntityRuleType.keyword,
      weight: 1,
      synonyms: <EntitySynonym>[
        EntitySynonym(
          value: 'male',
          terms: <String>['مرد', 'آقا', 'male', 'man'],
        ),
        EntitySynonym(
          value: 'female',
          terms: <String>['زن', 'خانم', 'female', 'woman'],
        ),
      ],
    ),
    EntityRule(
      id: 'keyword_goal',
      type: EntityType.goal,
      ruleType: EntityRuleType.keyword,
      weight: 1,
      synonyms: <EntitySynonym>[
        EntitySynonym(
          value: 'fat_loss',
          terms: <String>['کاهش وزن', 'چربی سوزی', 'fat loss', 'lose weight'],
        ),
        EntitySynonym(
          value: 'muscle_gain',
          terms: <String>['عضله سازی', 'حجم', 'muscle gain', 'bulk'],
        ),
        EntitySynonym(value: 'strength', terms: <String>['قدرت', 'strength']),
      ],
    ),
    EntityRule(
      id: 'keyword_equipment',
      type: EntityType.equipment,
      ruleType: EntityRuleType.keyword,
      weight: 0.9,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'dumbbell', terms: <String>['دمبل', 'dumbbell']),
        EntitySynonym(value: 'barbell', terms: <String>['هالتر', 'barbell']),
        EntitySynonym(
          value: 'treadmill',
          terms: <String>['تردمیل', 'treadmill'],
        ),
        EntitySynonym(
          value: 'resistance_band',
          terms: <String>['کش', 'resistance band'],
        ),
      ],
    ),
    EntityRule(
      id: 'keyword_experience',
      type: EntityType.experience,
      ruleType: EntityRuleType.keyword,
      weight: 0.9,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'beginner', terms: <String>['مبتدی', 'beginner']),
        EntitySynonym(
          value: 'intermediate',
          terms: <String>['متوسط', 'intermediate'],
        ),
        EntitySynonym(
          value: 'advanced',
          terms: <String>['حرفه ای', 'پیشرفته', 'advanced'],
        ),
      ],
    ),
    EntityRule(
      id: 'keyword_injury',
      type: EntityType.injury,
      ruleType: EntityRuleType.keyword,
      weight: 1,
      synonyms: <EntitySynonym>[
        EntitySynonym(
          value: 'knee_pain',
          terms: <String>['زانو درد', 'knee pain'],
        ),
        EntitySynonym(
          value: 'back_pain',
          terms: <String>['کمر درد', 'back pain'],
        ),
        EntitySynonym(
          value: 'shoulder_pain',
          terms: <String>['شانه درد', 'shoulder pain'],
        ),
      ],
    ),
    EntityRule(
      id: 'keyword_medical_condition',
      type: EntityType.medicalCondition,
      ruleType: EntityRuleType.keyword,
      weight: 1,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'diabetes', terms: <String>['دیابت', 'diabetes']),
        EntitySynonym(
          value: 'hypertension',
          terms: <String>['فشار خون', 'hypertension'],
        ),
        EntitySynonym(value: 'asthma', terms: <String>['آسم', 'asthma']),
      ],
    ),
    EntityRule(
      id: 'keyword_muscle_group',
      type: EntityType.muscleGroup,
      ruleType: EntityRuleType.keyword,
      weight: 0.9,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'chest', terms: <String>['سینه', 'chest']),
        EntitySynonym(value: 'back', terms: <String>['پشت', 'زیربغل', 'back']),
        EntitySynonym(value: 'legs', terms: <String>['پا', 'legs']),
        EntitySynonym(
          value: 'shoulders',
          terms: <String>['سرشانه', 'shoulders'],
        ),
        EntitySynonym(value: 'arms', terms: <String>['بازو', 'arms']),
      ],
    ),
    EntityRule(
      id: 'keyword_exercise_name',
      type: EntityType.exerciseName,
      ruleType: EntityRuleType.keyword,
      weight: 0.85,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'squat', terms: <String>['اسکوات', 'squat']),
        EntitySynonym(
          value: 'bench_press',
          terms: <String>['پرس سینه', 'bench press'],
        ),
        EntitySynonym(value: 'deadlift', terms: <String>['ددلیفت', 'deadlift']),
        EntitySynonym(value: 'plank', terms: <String>['پلانک', 'plank']),
      ],
    ),
    EntityRule(
      id: 'keyword_workout_day',
      type: EntityType.workoutDay,
      ruleType: EntityRuleType.keyword,
      weight: 0.8,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'today', terms: <String>['امروز', 'today']),
        EntitySynonym(value: 'tomorrow', terms: <String>['فردا', 'tomorrow']),
        EntitySynonym(value: 'monday', terms: <String>['دوشنبه', 'monday']),
        EntitySynonym(value: 'friday', terms: <String>['جمعه', 'friday']),
      ],
    ),
    EntityRule(
      id: 'keyword_time_expression',
      type: EntityType.timeExpression,
      ruleType: EntityRuleType.keyword,
      weight: 0.75,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'morning', terms: <String>['صبح', 'morning']),
        EntitySynonym(
          value: 'evening',
          terms: <String>['عصر', 'شب', 'evening', 'night'],
        ),
        EntitySynonym(value: 'week', terms: <String>['هفته', 'week']),
      ],
    ),
    EntityRule(
      id: 'keyword_supplement',
      type: EntityType.supplement,
      ruleType: EntityRuleType.keyword,
      weight: 0.9,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'creatine', terms: <String>['کراتین', 'creatine']),
        EntitySynonym(value: 'whey', terms: <String>['وی', 'whey']),
        EntitySynonym(value: 'bcaa', terms: <String>['bcaa', 'بی سی ای ای']),
      ],
    ),
    EntityRule(
      id: 'keyword_food',
      type: EntityType.food,
      ruleType: EntityRuleType.keyword,
      weight: 0.8,
      synonyms: <EntitySynonym>[
        EntitySynonym(value: 'rice', terms: <String>['برنج', 'rice']),
        EntitySynonym(value: 'chicken', terms: <String>['مرغ', 'chicken']),
        EntitySynonym(value: 'egg', terms: <String>['تخم مرغ', 'egg']),
        EntitySynonym(value: 'oat', terms: <String>['جو دوسر', 'oat']),
      ],
    ),
  ];

  /// Definitions keyed by type.
  final Map<EntityType, EntityDefinition> definitions;

  /// Extraction rules.
  final List<EntityRule> rules;

  /// Definition for [type].
  EntityDefinition? definitionFor(EntityType type) => definitions[type];

  /// Rules targeting [type].
  List<EntityRule> rulesFor(EntityType type) {
    return rules.where((rule) => rule.type == type).toList(growable: false);
  }
}
