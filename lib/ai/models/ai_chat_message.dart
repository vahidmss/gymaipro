/// مدل پیام چت برای سیستم هوش مصنوعی
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isTyping = false,
  });

  /// ایجاد پیام کاربر
  factory ChatMessage.user({required String content, String? id}) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      timestamp: DateTime.now(),
      type: ChatMessageType.user,
    );
  }

  /// ایجاد پیام هوش مصنوعی
  factory ChatMessage.ai({required String content, String? id}) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      timestamp: DateTime.now(),
      type: ChatMessageType.ai,
    );
  }

  /// ایجاد پیام در حال تایپ
  factory ChatMessage.typing() {
    return ChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      timestamp: DateTime.now(),
      type: ChatMessageType.ai,
      isTyping: true,
    );
  }

  /// ایجاد از Map (برای دیتابیس)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: (map['id'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: ChatMessageType.values.firstWhere(
        (e) =>
            e.name == (map['message_type'] as String?) ||
            e.name == (map['type'] as String?),
        orElse: () => ChatMessageType.user,
      ),
      isTyping: (map['isTyping'] as bool?) ?? false,
    );
  }

  /// ایجاد از Map دیتابیس
  factory ChatMessage.fromDatabaseMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: (map['id'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == (map['message_type'] as String?),
        orElse: () => ChatMessageType.user,
      ),
    );
  }
  final String id;
  final String content;
  final DateTime timestamp;
  final ChatMessageType type;
  final bool isTyping;

  /// کپی کردن پیام با تغییرات
  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    ChatMessageType? type,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// تبدیل به Map برای ذخیره
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isTyping': isTyping,
    };
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, type: $type, isTyping: $isTyping)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// نوع پیام چت
enum ChatMessageType { user, ai }

/// وضعیت چت
enum ChatStatus { idle, typing, sending, error }

/// تنظیمات چت
class ChatSettings {
  const ChatSettings({
    this.model = 'gpt-4o-mini',
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.streamResponse = false,
  });
  final String model;
  final double temperature;
  final int maxTokens;
  final bool streamResponse;

  ChatSettings copyWith({
    String? model,
    double? temperature,
    int? maxTokens,
    bool? streamResponse,
  }) {
    return ChatSettings(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      streamResponse: streamResponse ?? this.streamResponse,
    );
  }
}
