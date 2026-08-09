/// Local send lifecycle for optimistic chat bubbles (no backend column).
enum MessageSendStatus {
  sending,
  sent,
  failed,
}
