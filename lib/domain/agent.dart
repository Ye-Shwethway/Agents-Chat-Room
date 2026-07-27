import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent.freezed.dart';

/// Provider of an LLM API.
enum LlmProvider {
  gemini,
  nanogpt,
  openrouter,
  openai,
}

/// A configured AI that can participate in a Room.
///
/// Holds everything needed to talk to the model:
/// - display name (shown in transcript)
/// - provider + model id
/// - system prompt (persona)
/// - provider-specific configuration (model id, etc.)
///
/// API keys are NOT stored on the Agent — they live in KeyVault keyed by
/// `[provider]` (or per-agent id if a user wants multiple keys for the same
/// provider). Storing the key on Agent itself would force a write through
/// Drift whenever a key is rotated; keeping it in secure storage decouples.
@freezed
class Agent with _$Agent {
  const factory Agent({
    /// Local id (uuid).
    required String id,

    /// Display name shown in chat bubbles, e.g. "Optimist".
    required String name,

    /// LLM provider.
    required LlmProvider provider,

    /// Model id as the provider expects (e.g. "minimax/minimax-m3",
    /// "gemini-2.5-pro", "gpt-4o-mini").
    required String modelId,

    /// Persona / role. Sent as the first message of every API call for this
    /// Agent. May be empty for a neutral Agent.
    @Default('') String systemPrompt,

    /// When this Agent was created.
    required DateTime createdAt,
  }) = _Agent;
}