import 'package:budget/ai/providers/groq_provider.dart';
import 'package:budget/ai/services/ai_cost_controller.dart';
import 'package:flutter/foundation.dart';

/// High-level Groq AI service for Phase 2 features.
///
/// Wraps [GroqProvider] with rate limiting and small helper methods.
class GroqAIService {
  static final GroqAIService _instance = GroqAIService._internal();
  factory GroqAIService() => _instance;
  GroqAIService._internal();

  final GroqProvider _provider = GroqProvider();
  final AICostController _cost = AICostController();

  void configure({required String apiKey}) {
    _provider.configure(apiKey: apiKey);
  }

  bool get isConfigured => _provider.isConfigured;

  /// Generic chat call with Groq, returning plain text.
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 400,
  }) async {
    if (!isConfigured) {
      debugPrint('GroqAIService: Not configured');
      return null;
    }

    if (!await _cost.canMakeApiCall()) {
      debugPrint('GroqAIService: Daily API call limit reached');
      return null;
    }

    final response = await _provider.callAPI(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    await _cost.recordApiCall();
    return response;
  }

  /// JSON-style call (for predictions, alerts, etc.).
  Future<Map<String, dynamic>?> chatJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      debugPrint('GroqAIService: Not configured');
      return null;
    }

    if (!await _cost.canMakeApiCall()) {
      debugPrint('GroqAIService: Daily API call limit reached');
      return null;
    }

    final response = await _provider.callAPIJson(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    await _cost.recordApiCall();
    return response;
  }
}

