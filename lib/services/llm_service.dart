import 'dart:convert';
import 'package:dio/dio.dart';
import 'settings_service.dart';

class LlmWordResponse {
  final String lemma;
  final String translation;
  final List<String> otherMeanings;
  final String partOfSpeech;
  final String explanation;

  const LlmWordResponse({
    required this.lemma,
    required this.translation,
    required this.otherMeanings,
    required this.partOfSpeech,
    required this.explanation,
  });

  factory LlmWordResponse.fromJson(Map<String, dynamic> json, String fallbackWord) {
    List<String> meanings = [];
    if (json['other_meanings'] is List) {
      meanings = (json['other_meanings'] as List)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return LlmWordResponse(
      lemma: (json['lemma'] as String? ?? fallbackWord).trim(),
      translation: (json['translation'] as String? ?? 'Translation unavailable').trim(),
      otherMeanings: meanings,
      partOfSpeech: (json['part_of_speech'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
    );
  }
}

class LlmService {
  final SettingsService _settings;
  late final Dio _dio;

  LlmService(this._settings) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Cleans markdown wrappers like ```json ... ```
  static String extractCleanJson(String rawText) {
    String text = rawText.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  /// Request word translation and lemma with context
  Future<LlmWordResponse> translateWord({
    required String word,
    required String contextSentence,
  }) async {
    final apiKey = _settings.apiKey;
    var baseUrl = _settings.baseUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final model = _settings.model;
    final targetLang = _settings.targetLanguage;
    final nativeLang = _settings.nativeLanguage;

    if (apiKey.isEmpty) {
      throw Exception('API Key is missing. Please configure it in Settings.');
    }

    final prompt = '''
You are an expert language teacher and translator.
Analyze the target word in the given context sentence.
Target language: $targetLang
Native language for translation: $nativeLang

Target word: "$word"
Context sentence: "$contextSentence"

Respond ONLY with a valid JSON object without markdown code blocks, using exactly these keys:
{
  "lemma": "dictionary / base form of the word in $targetLang",
  "translation": "accurate context-aware translation into $nativeLang",
  "other_meanings": ["common meaning 2", "common meaning 3"],
  "part_of_speech": "noun / verb / adjective / etc. in $nativeLang",
  "explanation": "brief grammatical note, tense, or idiom nuance if applicable"
}
''';

    final requestUrl = '$baseUrl/chat/completions';
    final requestBody = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a precise language learning assistant. Always return strictly valid raw JSON without formatting, markdown, or commentary.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.2,
      'max_tokens': 400,
    };

    try {
      final response = await _dio.post(
        requestUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String rawContent = '';
        if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
          rawContent = data['choices'][0]['message']?['content'] ?? '';
        } else if (data is String) {
          final parsed = jsonDecode(data);
          rawContent = parsed['choices'][0]['message']?['content'] ?? '';
        }

        final cleanJson = extractCleanJson(rawContent);
        final decoded = jsonDecode(cleanJson);
        if (decoded is Map<String, dynamic>) {
          return LlmWordResponse.fromJson(decoded, word);
        }
        throw FormatException('Unexpected response format: $cleanJson');
      } else {
        throw Exception('API Error [${response.statusCode}]: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('API error (${e.response?.statusCode}): ${e.response?.data ?? e.message}');
      }
      throw Exception('Connection failed: ${e.message}');
    }
  }

  /// Test connection with current settings
  Future<bool> testConnection() async {
    final apiKey = _settings.apiKey;
    var baseUrl = _settings.baseUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final model = _settings.model;

    if (apiKey.isEmpty) {
      throw Exception('API Key cannot be empty.');
    }

    final requestUrl = '$baseUrl/chat/completions';
    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': 'Say "OK" in one word.'}
      ],
      'max_tokens': 5,
    };

    final response = await _dio.post(
      requestUrl,
      data: requestBody,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    return response.statusCode == 200;
  }
}
