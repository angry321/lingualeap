import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_item.dart';
import '../providers/app_providers.dart';
import '../services/srs_service.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<WordItem> words;

  const FlashcardsScreen({super.key, required this.words});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _currentIndex = 0;
  bool _isAnswerRevealed = false;
  int _reviewedCount = 0;

  void _revealAnswer() {
    setState(() {
      _isAnswerRevealed = true;
    });
  }

  Future<void> _handleRating(ReviewRating rating) async {
    final currentWord = widget.words[_currentIndex];
    final wordsProvider = context.read<WordsProvider>();

    await wordsProvider.reviewWord(currentWord, rating);

    setState(() {
      _reviewedCount++;
      _isAnswerRevealed = false;
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Повторение слов')),
        body: const Center(
          child: Text('Нет слов для повторения.'),
        ),
      );
    }

    if (_currentIndex >= widget.words.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Повторение завершено')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 90,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                Text(
                  'Отличная работа!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Вы повторили $_reviewedCount слов. Интервалы повторения были обновлены по алгоритму SM-2.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Вернуться к словарю'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentWord = widget.words[_currentIndex];
    final progress = (_currentIndex + 1) / widget.words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Карточка ${_currentIndex + 1} из ${widget.words.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: !_isAnswerRevealed ? _revealAnswer : null,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Word / Lemma
                              Text(
                                currentWord.lemma,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (currentWord.originalForm.toLowerCase() != currentWord.lemma.toLowerCase()) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'в тексте: ${currentWord.originalForm}',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              if (!_isAnswerRevealed) ...[
                                const Icon(
                                  Icons.touch_app_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Нажмите на карточку, чтобы открыть перевод',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ] else ...[
                                const Divider(height: 32),
                                // Translation
                                Text(
                                  currentWord.translation,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (currentWord.partOfSpeech.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(
                                      currentWord.partOfSpeech,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                                if (currentWord.explanation.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    currentWord.explanation,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                                if (currentWord.contextSentence.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Контекст: "${currentWord.contextSentence}"',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Buttons
              if (!_isAnswerRevealed)
                FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _revealAnswer,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Показать перевод'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildRatingButton(
                      label: 'Снова\n(1 дн)',
                      color: Colors.red.shade600,
                      rating: ReviewRating.again,
                    ),
                    _buildRatingButton(
                      label: 'Трудно\n(2-3 дн)',
                      color: Colors.orange.shade700,
                      rating: ReviewRating.hard,
                    ),
                    _buildRatingButton(
                      label: 'Хорошо\n(3-5 дн)',
                      color: Colors.blue.shade600,
                      rating: ReviewRating.good,
                    ),
                    _buildRatingButton(
                      label: 'Легко\n(7+ дн)',
                      color: Colors.green.shade600,
                      rating: ReviewRating.easy,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required Color color,
    required ReviewRating rating,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _handleRating(rating),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
