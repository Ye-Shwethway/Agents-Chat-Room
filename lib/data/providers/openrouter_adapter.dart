import 'package:dio/dio.dart';

import 'provider_adapter.dart';

/// Adapter for OpenRouter API (https://openrouter.ai).
///
/// OpenAI-compatible endpoint: POST https://openrouter.ai/api/v1/chat/completions
/// Authentication: `Authorization: Bearer {key}` header.
class OpenRouterAdapter implements ProviderAdapter {
  @override
  String get providerName => 'openrouter';

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  Future<String> callAgent({
    required String modelId,
    required String apiKey,
    required List<Map<String, String>> messages,
  }) async {
    final response = await Dio().post(
      _baseUrl,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://github.com/Ye-Shwethway/Agents-Chat-Room',
        'X-Title': 'Agent Chatroom',
      },
      data: {
        'model': modelId,
        'messages': messages,
        'max_tokens': 4096,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error: ${response.statusCode} - ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenRouter returned no choices');
    }
    return choices[0]['message']?['content'] ?? '';
  }
}