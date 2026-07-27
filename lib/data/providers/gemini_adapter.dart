import 'package:dio/dio.dart';

import 'provider_adapter.dart';

/// Adapter for Google Gemini API (https://ai.google.dev/api).
///
/// Endpoint: POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
/// Authentication: `x-goog-api-key: {key}` header or query param.
class GeminiAdapter implements ProviderAdapter {
  @override
  String get providerName => 'gemini';

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  Future<String> callAgent({
    required String modelId,
    required String apiKey,
    required List<Map<String, String>> messages,
  }) async {
    final parts = messages.map((m) {
      return {'text': m['content']!};
    }).toList();

    final response = await Dio().post(
      '$_baseUrl/$modelId:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'contents': [
          {'role': 'user', 'parts': parts},
        ],
        'generationConfig': {'maxOutputTokens': 4096},
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates');
    }
    final text = candidates[0]['content']?['parts']?[0]?['text'];
    return text ?? '';
  }
}