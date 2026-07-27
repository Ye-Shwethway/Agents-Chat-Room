import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

/// Who produced a message in the transcript.
enum MessageRole {
  /// The Orchestrator (human).
  orchestrator,

  /// One of the Roster Agents.
  agent,

  /// System note (debate paused, agent stalled, etc.). Not from an LLM.
  system,
}

/// State of an Agent's reply within a round.
enum MessageStatus {
  /// Reply is being generated.
  pending,

  /// Reply finished successfully.
  ok,

  /// Reply failed after the retry budget was exhausted. Body contains
  /// the error reason.
  failed,

  /// Agent didn't reply within the stall timeout. Other Agents continue.
  stalled,
}

/// A single message in a Room's transcript.
@freezed
class Message with _$Message {
  const factory Message({
    required String id,

    /// Room this message belongs to.
    required String roomId,

    /// Which Agent produced this (null for orchestrator / system).
    @Default(null) String? agentId,

    /// Role tag.
    required MessageRole role,

    /// Message body. Empty for `pending`; final text for `ok`; error reason
    /// for `failed`.
    @Default('') String content,

    /// Round index in a debate (1-based; 0 for single-mode messages).
    @Default(0) int round,

    /// Order within a round (for tie-breaking when Agents reply in parallel).
    @Default(0) int ordinal,

    required MessageStatus status,

    required DateTime createdAt,
  }) = _Message;
}