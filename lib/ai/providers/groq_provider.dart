import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Groq AI Provider - Fast, free alternative to Gemini
///
/// Free tier: 14,400 requests per day
/// Get API key: https://console.groq.com/keys
class GroqProvider {
  String? _apiKey;
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant'; // Fast and free

  void configure({required String apiKey}) {
    _apiKey = apiKey;
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Call Groq API and return text response
  Future<String?> callAPI({
    required String systemPrompt,
    required String userPrompt,
    bool expectJson = false,
  }) async {
    if (!isConfigured) {
      debugPrint('❌ GroqProvider: API key not configured');
      return null;
    }

    debugPrint('🚀 GroqProvider: Making API call...');
    debugPrint('GroqProvider: Model: $_model');

    try {
      final response = await http
          .post(
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
              'max_tokens': expectJson ? 1000 : 500,
              if (expectJson) 'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          debugPrint('✅ GroqProvider: Successfully received response');
          return content.toString().trim();
        } else {
          debugPrint('⚠️ GroqProvider: Response 200 but no content in choices');
          debugPrint('GroqProvider: Response body: ${response.body}');
        }
      } else {
        debugPrint('❌ GroqProvider: API error ${response.statusCode}');
        debugPrint('GroqProvider: Response body: ${response.body}');
        if (response.statusCode == 401) {
          debugPrint(
              '❌ GroqProvider: Invalid API key - check your GROQ_API_KEY in .env');
        } else if (response.statusCode == 429) {
          debugPrint('⚠️ GroqProvider: Rate limit exceeded');
        } else if (response.statusCode == 400) {
          debugPrint('❌ GroqProvider: Bad request - check API parameters');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ GroqProvider: Error calling API: $e');
      debugPrint('GroqProvider: Stack trace: $stackTrace');
      if (e.toString().contains('TimeoutException')) {
        debugPrint('⚠️ GroqProvider: Request timed out after 30 seconds');
      } else if (e.toString().contains('SocketException')) {
        debugPrint(
            '⚠️ GroqProvider: Network error - check internet connection');
      }
    }
    return null;
  }

  /// Call Groq API expecting JSON response
  Future<Map<String, dynamic>?> callAPIJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await callAPI(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      expectJson: true,
    );

    if (response != null) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('GroqProvider: Failed to parse JSON response: $e');
      }
    }
    return null;
  }
}
