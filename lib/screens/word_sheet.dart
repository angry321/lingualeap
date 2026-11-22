import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_item.dart';
import '../providers/app_providers.dart';
import '../services/llm_service.dart';
import 'settings_screen.dart';

class WordSheet extends StatefulWidget {
  final String word;
  final String cleanWord;
  final String contextSentence;

  const WordSheet({
    super.key,
    required this.word,
    required this.cleanWord,
    required this.contextSentence,
  });

  static void show(
    BuildContext context, {
    required String word,
    required String cleanWord,
    required String contextSentence,
  }) {
    final isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: WordSheet(
              word: word,
              cleanWord: cleanWord,
              contextSentence: contextSentence,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => WordSheet(
          word: word,
          cleanWord: cleanWord,
          contextSentence: contextSentence,
        ),
      );
    }
  }

  @override
  State<WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<WordSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  WordItem? _savedWord;
  LlmWordResponse? _llmResponse;

  @override
  void initState() {
    super.initState();
    _checkOrFetchWord();
  }

  void _checkOrFetchWord() {
    final wordsProvider = context.read<WordsProvider>();
    final existing = wordsProvider.findWord(widget.cleanWord);

    if (existing != null) {
      setState(() {
        _savedWord = existing;
      });
    } else {
      _fetchFromLlm();
    }
  }

  Future<void> _fetchFromLlm() async {
    final settingsProvider = context.read<SettingsProvider>();

    if (settingsProvider.apiKey.trim().isEmpty) {
      setState(() {
        _errorMessage = 'API Key is not configured. Go to Settings to add your key.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await settingsProvider.llmService.translateWord(
        word: widget.cleanWord,
        contextSentence: widget.contextSentence,
      );
      if (mounted) {
        setState(() {
          _llmResponse = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWordWithStatus(String status) async {
    final wordsProvider = context.read<WordsProvider>();

    final lemma = _savedWord?.lemma ?? _llmResponse?.lemma ?? widget.cleanWord;
    final translation = _savedWord?.translation ?? _llmResponse?.translation ?? '';
    final partOfSpeech = _savedWord?.partOfSpeech ?? _llmResponse?.partOfSpeech ?? '';
    final explanation = _savedWord?.explanation ?? _llmResponse?.explanation ?? '';

    final word = WordItem(
      id: _savedWord?.id,
      lemma: lemma,
      originalForm: widget.word,
      translation: translation,
      partOfSpeech: partOfSpeech,
      explanation: explanation,
      contextSentence: widget.contextSentence,
      status: status,
      nextReviewAt: DateTime.now().add(status == 'known' ? const Duration(days: 180) : const Duration(days: 1)).millisecondsSinceEpoch,
      intervalDays: status == 'known' ? 180 : 1,
      easeFactor: 2.5,
    );

    await wordsProvider.saveWord(word);
    if (mounted) {
      setState(() {
        _savedWord = word;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'known' ? 'Добавлено в "Выученные"' : 'Добавлено в "Изучаю"',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteWord() async {
    if (_savedWord == null) return;
    final wordsProvider = context.read<WordsProvider>();
    await wordsProvider.deleteWord(_savedWord!);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Слово удалено из словаря'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSheet = MediaQuery.of(context).size.width <= 700;

    final containerDecoration = BoxDecoration(
      color: theme.scaffoldBackgroundColor,
      borderRadius: isSheet
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, -2),
        ),
      ],
    );

    return Container(
      decoration: containerDecoration,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle for bottom sheet
              if (isSheet)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Header: Original word & close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.word,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_savedWord != null || _llmResponse != null)
                          Text(
                            'Лемма: ${_savedWord?.lemma ?? _llmResponse?.lemma ?? widget.cleanWord}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Content Body
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('ИИ переводит слово в контексте...'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ошибка получения перевода',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: _fetchFromLlm,
                            child: const Text('Повторить'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const SettingsScreen(),
                                ),
                              );
                            },
                            child: const Text('Настройки API'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildTranslationDetails(theme),
              ],

              const SizedBox(height: 20),

              // Action buttons (Learning / Known / Delete)
              if (!_isLoading && _errorMessage == null)
                _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationDetails(ThemeData theme) {
    final translation = _savedWord?.translation ?? _llmResponse?.translation ?? '';
    final partOfSpeech = _savedWord?.partOfSpeech ?? _llmResponse?.partOfSpeech ?? '';
    final explanation = _savedWord?.explanation ?? _llmResponse?.explanation ?? '';
    final otherMeanings = _llmResponse?.otherMeanings ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translation & POS
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                translation,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (partOfSpeech.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  partOfSpeech,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),

        // Other meanings
        if (otherMeanings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Другие значения: ${otherMeanings.join(", ")}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],

        // Grammatical Explanation
        if (explanation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explanation,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Context sentence
        if (widget.contextSentence.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Контекст:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.contextSentence,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        // Re-translate via AI button if saved word exists
        if (_savedWord != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _fetchFromLlm,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Перевести заново через ИИ'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final isLearning = _savedWord?.status == 'learning';
    final isKnown = _savedWord?.status == 'known';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isLearning ? Colors.amber.shade700 : null,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _saveWordWithStatus('learning'),
                icon: Icon(isLearning ? Icons.check : Icons.school_outlined),
                label: Text(isLearning ? 'Изучаю (активно)' : 'Изучаю'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: isKnown ? Colors.green.shade600 : null,
                  foregroundColor: isKnown ? Colors.white : null,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _saveWordWithStatus('known'),
                icon: Icon(isKnown ? Icons.done_all : Icons.check_circle_outline),
                label: Text(isKnown ? 'Знаю (выучено)' : 'Знаю'),
              ),
            ),
          ],
        ),
        if (_savedWord != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: _deleteWord,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Удалить из словаря'),
          ),
        ],
      ],
    );
  }
}
