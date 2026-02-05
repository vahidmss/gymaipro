/// مدل سوال پرسشنامه
class WorkoutQuestion {
  WorkoutQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.category,
    required this.isRequired,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.options,
  });

  factory WorkoutQuestion.fromJson(Map<String, dynamic> json) {
    return WorkoutQuestion(
      id: json['id'] as String,
      questionText: json['question_text'] as String,
      questionType: QuestionType.fromString(json['question_type'] as String),
      category: json['category'] as String,
      options: json['options'],
      isRequired: json['is_required'] as bool? ?? true,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String questionText;
  final QuestionType questionType;
  final String category;
  final dynamic options;
  final bool isRequired;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'question_type': questionType.toString(),
      'category': category,
      'options': options,
      'is_required': isRequired,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// انواع سوالات
enum QuestionType {
  singleChoice,
  multipleChoice,
  text,
  number,
  slider;

  static QuestionType fromString(String value) {
    switch (value) {
      case 'single_choice':
        return QuestionType.singleChoice;
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'text':
        return QuestionType.text;
      case 'number':
        return QuestionType.number;
      case 'slider':
        return QuestionType.slider;
      default:
        throw ArgumentError('Invalid question type: $value');
    }
  }

  @override
  String toString() {
    switch (this) {
      case QuestionType.singleChoice:
        return 'single_choice';
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.text:
        return 'text';
      case QuestionType.number:
        return 'number';
      case QuestionType.slider:
        return 'slider';
    }
  }
}

/// مدل پاسخ سوال (برای استفاده داخلی)
class WorkoutQuestionResponse {
  WorkoutQuestionResponse({
    required this.questionId,
    this.answerText,
    this.answerNumber,
    this.answerChoices,
  });

  factory WorkoutQuestionResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutQuestionResponse(
      questionId: json['question_id'] as String,
      answerText: json['answer_text'] as String?,
      answerNumber: json['answer_number'] != null
          ? (json['answer_number'] as num).toDouble()
          : null,
      answerChoices: json['answer_choices'] != null
          ? List<String>.from(json['answer_choices'] as List)
          : null,
    );
  }
  final String questionId;
  final String? answerText;
  final double? answerNumber;
  final List<String>? answerChoices;

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer_text': answerText,
      'answer_number': answerNumber,
      'answer_choices': answerChoices,
    };
  }
}

/// مدل پاسخ‌های کامل کاربر (جدول جدید)
class WorkoutUserResponses {
  WorkoutUserResponses({
    required this.id,
    required this.userId,
    required this.responses,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
  });

  factory WorkoutUserResponses.fromJson(Map<String, dynamic> json) {
    final responsesJson = Map<String, dynamic>.from(
      json['responses_json'] as Map,
    );
    final responses = <String, WorkoutQuestionResponse>{};

    for (final entry in responsesJson.entries) {
      responses[entry.key] = WorkoutQuestionResponse.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    return WorkoutUserResponses(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      responses: responses,
      sessionId: json['session_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String userId;
  final Map<String, WorkoutQuestionResponse> responses;
  final String? sessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    final responsesJson = <String, dynamic>{};
    for (final entry in responses.entries) {
      responsesJson[entry.key] = entry.value.toJson();
    }

    return {
      'id': id,
      'user_id': userId,
      'responses_json': responsesJson,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// مدل جلسه پرسشنامه
class WorkoutQuestionnaireSession {
  WorkoutQuestionnaireSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory WorkoutQuestionnaireSession.fromJson(Map<String, dynamic> json) {
    return WorkoutQuestionnaireSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: SessionStatus.fromString(json['status'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String userId;
  final SessionStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status.toString(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// وضعیت جلسه پرسشنامه
enum SessionStatus {
  inProgress,
  completed,
  abandoned;

  static SessionStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return SessionStatus.inProgress;
      case 'completed':
        return SessionStatus.completed;
      case 'abandoned':
        return SessionStatus.abandoned;
      default:
        throw ArgumentError('Invalid session status: $value');
    }
  }

  @override
  String toString() {
    switch (this) {
      case SessionStatus.inProgress:
        return 'in_progress';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.abandoned:
        return 'abandoned';
    }
  }
}

/// مدل کامل پرسشنامه با سوالات و پاسخ‌ها
class WorkoutQuestionnaire {
  WorkoutQuestionnaire({
    required this.questions,
    required this.responses,
    this.session,
  });
  final List<WorkoutQuestion> questions;
  final Map<String, WorkoutQuestionResponse> responses;
  final WorkoutQuestionnaireSession? session;

  /// دریافت پاسخ برای یک سوال
  WorkoutQuestionResponse? getResponseForQuestion(String questionId) {
    return responses[questionId];
  }

  /// بررسی تکمیل بودن پرسشنامه
  bool get isCompleted {
    if (session?.status != SessionStatus.completed) return false;

    for (final question in questions) {
      if (question.isRequired && !responses.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

  /// محاسبه درصد تکمیل
  double get completionPercentage {
    if (questions.isEmpty) return 0;

    int answeredRequired = 0;
    int totalRequired = 0;

    for (final question in questions) {
      if (question.isRequired) {
        totalRequired++;
        if (responses.containsKey(question.id)) {
          answeredRequired++;
        }
      }
    }

    return totalRequired > 0 ? (answeredRequired / totalRequired) * 100 : 0.0;
  }
}
