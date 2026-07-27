import 'package:dio/dio.dart';

import 'provider_adapter.dart';

/// Adapter for NanoGPT API (https://nano-gpt.com).
///
/// OpenAI-compatible endpoint: POST https://nano-gpt.com/api/v1/chat/completions
/// Authentication: `Authorization: Bearer {key}` header.
class NanoGptAdapter implements ProviderAdapter {
  @override
  String get providerName => 'nanogpt';

  static const _baseUrl = 'https://nano-gpt.com/api/v1/chat/completions';

  @override
  Future<String> callAgent({
    required String modelId,
    required String apiKey,
    required List<Map<String, String>> messages,
  }) async {
    final dio = Dio(BaseOptions(headers: {
      'Authorization': 'Bearer $apiKey',
    }));
    final response = await dio.post(
      _baseUrl,
      data: {
        'model': modelId,
        'messages': messages,
        'max_tokens': 4096,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('NanoGPT API error: ${response.statusCode} - ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('NanoGPT returned no choices');
    }
    return choices[0]['message']?['content'] ?? '';
  }
}