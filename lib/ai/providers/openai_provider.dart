import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OpenAI AI Provider - Cost-efficient AI for financial analysis
/// 
/// Uses gpt-4o-mini model for optimal cost/performance
/// Get API key: https://platform.openai.com/api-keys
class OpenAIProvider {
  String? _apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini'; // Cost-efficient model

  void configure({required String apiKey}) {
    _apiKey = apiKey;
    debugPrint('✅ OpenAIProvider: Configured with API key');
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Call OpenAI API and return text response
  Future<String?> callAPI({
    required String systemPrompt,
    required String userPrompt,
    bool expectJson = false,
    int maxTokens = 500,
  }) async {
    if (!isConfigured) {
      debugPrint('❌ OpenAIProvider: API key not configured');
      return null;
    }

    debugPrint('🚀 OpenAIProvider: Making API call with model: $_model');
    debugPrint('OpenAIProvider: Max tokens: $maxTokens');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3,
          'max_tokens': maxTokens,
          if (expectJson) 'response_format': {'type': 'json_object'},
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          debugPrint('✅ OpenAIProvider: Successfully received response');
          return content.toString().trim();
        } else {
          debugPrint('⚠️ OpenAIProvider: Response 200 but no content in choices');
          debugPrint('OpenAIProvider: Response body: ${response.body}');
        }
      } else {
        debugPrint('❌ OpenAIProvider: API error ${response.statusCode}');
        debugPrint('OpenAIProvider: Response body: ${response.body}');
        if (response.statusCode == 401) {
          debugPrint('❌ OpenAIProvider: Invalid API key - check your OPENAI_API_KEY in .env');
        } else if (response.statusCode == 429) {
          debugPrint('⚠️ OpenAIProvider: Rate limit exceeded');
        } else if (response.statusCode == 400) {
          debugPrint('❌ OpenAIProvider: Bad request - check API parameters');
        } else if (response.statusCode == 500) {
          debugPrint('❌ OpenAIProvider: OpenAI server error - retry later');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ OpenAIProvider: Error calling API: $e');
      debugPrint('OpenAIProvider: Stack trace: $stackTrace');
      if (e.toString().contains('TimeoutException')) {
        debugPrint('⚠️ OpenAIProvider: Request timed out after 30 seconds');
      } else if (e.toString().contains('SocketException')) {
        debugPrint('⚠️ OpenAIProvider: Network error - check internet connection');
      }
    }
    return null;
  }

  /// Call OpenAI API expecting JSON response
  Future<Map<String, dynamic>?> callAPIJson({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 1000,
  }) async {
    final response = await callAPI(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      expectJson: true,
      maxTokens: maxTokens,
    );

    if (response != null) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('OpenAIProvider: Failed to parse JSON response: $e');
        debugPrint('OpenAIProvider: Raw response: $response');
      }
    }
    return null;
  }

  /// Get usage information from response (for cost tracking)
  Map<String, dynamic>? parseUsage(Map<String, dynamic> response) {
    try {
      return response['usage'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
