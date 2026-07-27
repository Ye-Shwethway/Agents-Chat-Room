import 'package:dio/dio.dart';

/// Abstract adapter that every LLM provider must implement.
///
/// The DebateEngine calls [callAgent] with a list of messages
/// (system prompt + chat history). The provider returns the model's
/// response body.
///
/// Keys are passed separately by the DebateEngine (from KeyVault).
abstract class ProviderAdapter {
  const ProviderAdapter();

  /// Provider name, e.g. 'gemini', 'nanogpt'.
  String get providerName;

  /// Call the LLM with a list of messages.
  ///
  /// [messages] is the full chat history including the system prompt
  /// at index 0. [modelId] is the provider-specific model identifier.
  /// [apiKey] is the secret API key.
  Future<String> callAgent({
    required String modelId,
    required String apiKey,
    required List<Map<String, String>> messages,
  });
}