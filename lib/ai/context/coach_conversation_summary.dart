/// Placeholder conversation summary for future chat history integration.
///
/// Populated by [ConversationSummaryService] after enough chat turns.
class CoachConversationSummary {
  const CoachConversationSummary({
    this.summary,
    this.messageCount = 0,
    this.lastUpdatedAt,
    this.placeholder = true,
  });

  /// Empty placeholder used until chat summarization is implemented.
  static const CoachConversationSummary empty = CoachConversationSummary();

  /// Short summary of the recent conversation.
  final String? summary;

  /// Number of messages represented by [summary].
  final int messageCount;

  /// Last time the summary was refreshed.
  final DateTime? lastUpdatedAt;

  /// Whether this summary is still a placeholder.
  final bool placeholder;
}
