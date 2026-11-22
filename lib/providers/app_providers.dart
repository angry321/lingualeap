import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/material_item.dart';
import '../models/segment.dart';
import '../models/word_item.dart';
import '../services/db_service.dart';
import '../services/llm_service.dart';
import '../services/settings_service.dart';
import '../services/srs_service.dart';
import '../services/youtube_service.dart';
import '../utils/text_tokenizer.dart';

// ==================== SETTINGS PROVIDER ====================

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;
  late final LlmService _llmService;

  SettingsProvider(this._service) {
    _llmService = LlmService(_service);
  }

  LlmService get llmService => _llmService;
  SettingsService get service => _service;

  String get apiKey => _service.apiKey;
  String get baseUrl => _service.baseUrl;
  String get model => _service.model;
  String get targetLanguage => _service.targetLanguage;
  String get nativeLanguage => _service.nativeLanguage;
  bool get autoScroll => _service.autoScroll;
  double get fontSize => _service.fontSize;
  ThemeMode get themeMode => _service.themeMode;

  Future<void> updateApiKey(String value) async {
    await _service.setApiKey(value);
    notifyListeners();
  }

  Future<void> updateBaseUrl(String value) async {
    await _service.setBaseUrl(value);
    notifyListeners();
  }

  Future<void> updateModel(String value) async {
    await _service.setModel(value);
    notifyListeners();
  }

  Future<void> updateTargetLanguage(String value) async {
    await _service.setTargetLanguage(value);
    notifyListeners();
  }

  Future<void> updateNativeLanguage(String value) async {
    await _service.setNativeLanguage(value);
    notifyListeners();
  }

  Future<void> updateAutoScroll(bool value) async {
    await _service.setAutoScroll(value);
    notifyListeners();
  }

  Future<void> updateFontSize(double value) async {
    await _service.setFontSize(value);
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _service.setThemeMode(mode);
    notifyListeners();
  }

  Future<bool> testConnection() async {
    return await _llmService.testConnection();
  }
}

// ==================== WORDS PROVIDER ====================

class WordsProvider extends ChangeNotifier {
  final DBService _db = DBService.instance;
  Map<String, WordItem> _wordsMap = {};
  List<WordItem> _wordsList = [];
  bool _isLoading = false;

  Map<String, WordItem> get wordsMap => _wordsMap;
  List<WordItem> get wordsList => _wordsList;
  bool get isLoading => _isLoading;

  Future<void> loadWords({String? statusFilter, String? searchQuery}) async {
    _isLoading = true;
    notifyListeners();

    _wordsMap = await _db.getWordsMap();
    _wordsList = await _db.getAllWords(statusFilter: statusFilter, searchQuery: searchQuery);

    _isLoading = false;
    notifyListeners();
  }

  WordItem? findWord(String token) {
    final clean = token.toLowerCase().trim();
    if (_wordsMap.containsKey(clean)) {
      return _wordsMap[clean];
    }
    // Also search by original form matching
    for (final item in _wordsMap.values) {
      if (item.originalForm.toLowerCase().trim() == clean) {
        return item;
      }
    }
    return null;
  }

  Future<void> saveWord(WordItem word) async {
    await _db.insertOrUpdateWord(word);
    final clean = word.lemma.toLowerCase().trim();
    _wordsMap[clean] = word;
    await loadWords();
  }

  Future<void> deleteWord(WordItem word) async {
    if (word.id != null) {
      await _db.deleteWordById(word.id!);
    } else {
      await _db.deleteWord(word.lemma);
    }
    _wordsMap.remove(word.lemma.toLowerCase().trim());
    await loadWords();
  }

  Future<void> setWordStatus(WordItem word, String status) async {
    WordItem updated;
    if (status == 'known') {
      updated = SrsService.markAsKnown(word);
    } else {
      updated = SrsService.markAsLearning(word);
    }
    await saveWord(updated);
  }

  Future<void> reviewWord(WordItem word, ReviewRating rating) async {
    final updated = SrsService.processReview(word, rating);
    await saveWord(updated);
  }
}

// ==================== MATERIALS PROVIDER ====================

class MaterialsProvider extends ChangeNotifier {
  final DBService _db = DBService.instance;
  final YouTubeService _ytService = YouTubeService();

  List<MaterialItem> _materials = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MaterialItem> get materials => _materials;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMaterials() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _materials = await _db.getMaterials();
    } catch (e) {
      _errorMessage = 'Failed to load materials: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MaterialItem> addYouTubeMaterial(String urlOrId, {String? preferredLang}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _ytService.fetchVideoWithCaptions(
        urlOrId,
        preferredLanguageCode: preferredLang,
      );

      final material = YouTubeService.createMaterial(
        title: result.title,
        videoId: result.videoId,
        segments: result.segments,
      );

      final id = await _db.insertMaterial(material);
      final savedMaterial = material.copyWith(id: id);
      await loadMaterials();
      return savedMaterial;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MaterialItem> addTextMaterial({required String title, required String text}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sentences = TextTokenizer.splitIntoSentences(text);
      if (sentences.isEmpty) {
        throw Exception('Text is empty or could not be parsed.');
      }

      final segments = sentences.map((s) => Segment(text: s, startMs: 0, durationMs: 0)).toList();
      final segmentsJson = jsonEncode(segments.map((s) => s.toJson()).toList());

      final material = MaterialItem(
        title: title.trim().isEmpty ? 'Untitled Text' : title.trim(),
        sourceType: 'text',
        segmentsJson: segmentsJson,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await _db.insertMaterial(material);
      final saved = material.copyWith(id: id);
      await loadMaterials();
      return saved;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMaterial(int id) async {
    await _db.deleteMaterial(id);
    await loadMaterials();
  }

  @override
  void dispose() {
    _ytService.dispose();
    super.dispose();
  }
}
