import 'package:dio/dio.dart';

import 'provider_adapter.dart';

/// Adapter for OpenAI API (https://platform.openai.com).
///
/// OpenAI-compatible endpoint: POST https://api.openai.com/v1/chat/completions
/// Authentication: `Authorization: Bearer {key}` header.
class OpenAiAdapter implements ProviderAdapter {
  @override
  String get providerName => 'openai';

  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';

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
        'Content-Type': 'application/json',
      },
      data: {
        'model': modelId,
        'messages': messages,
        'max_tokens': 4096,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenAI returned no choices');
    }
    return choices[0]['message']?['content'] ?? '';
  }
}