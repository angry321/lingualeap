import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/word_item.dart';
import '../providers/app_providers.dart';
import 'flashcards_screen.dart';
import 'word_sheet.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'learning', 'known'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWords();
    });
  }

  void _loadWords() {
    context.read<WordsProvider>().loadWords(
          statusFilter: _selectedFilter == 'all' ? null : _selectedFilter,
          searchQuery: _searchController.text.trim(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startFlashcards(List<WordItem> words) {
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('В этой категории нет слов для повторения.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FlashcardsScreen(words: words),
      ),
    ).then((_) => _loadWords());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Словарь и SRS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _loadWords,
          ),
        ],
      ),
      body: Consumer<WordsProvider>(
        builder: (context, wordsProvider, child) {
          final words = wordsProvider.wordsList;

          final learningCount = wordsProvider.wordsMap.values.where((w) => w.isLearning).length;
          final knownCount = wordsProvider.wordsMap.values.where((w) => w.isKnown).length;
          final totalCount = wordsProvider.wordsMap.length;

          return Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadWords(),
                  decoration: InputDecoration(
                    hintText: 'Поиск по слову или переводу...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadWords();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),

              // Filter Chips & Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('Все ($totalCount)'),
                        selected: _selectedFilter == 'all',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'all');
                          _loadWords();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.school, size: 16, color: Colors.amber),
                        label: Text('Изучаю ($learningCount)'),
                        selected: _selectedFilter == 'learning',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'learning');
                          _loadWords();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        label: Text('Выучено ($knownCount)'),
                        selected: _selectedFilter == 'known',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'known');
                          _loadWords();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Start Flashcards CTA Button
              if (learningCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        final learningWords = wordsProvider.wordsMap.values
                            .where((w) => w.isLearning)
                            .toList();
                        _startFlashcards(learningWords);
                      },
                      icon: const Icon(Icons.style),
                      label: Text('Тренировать карточки ($learningCount)'),
                    ),
                  ),
                ),

              const Divider(height: 16),

              // Word list
              Expanded(
                child: wordsProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : words.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: words.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = words[index];
                              return _buildWordTile(item, theme);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWordTile(WordItem item, ThemeData theme) {
    final isLearning = item.isLearning;
    final nextReview = DateFormat('dd.MM.yy').format(
      DateTime.fromMillisecondsSinceEpoch(item.nextReviewAt),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isLearning ? Colors.amber.withOpacity(0.25) : Colors.green.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLearning ? Icons.school : Icons.check,
          color: isLearning ? Colors.amber.shade800 : Colors.green.shade800,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            item.lemma,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (item.partOfSpeech.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.partOfSpeech,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            item.translation,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Интервал: ${item.intervalDays} дн. • След. повтор: $nextReview',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          final wordsProvider = context.read<WordsProvider>();
          if (action == 'toggle') {
            await wordsProvider.setWordStatus(
              item,
              item.isLearning ? 'known' : 'learning',
            );
          } else if (action == 'delete') {
            await wordsProvider.deleteWord(item);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'toggle',
            child: Text(item.isLearning ? 'Отметить как выученное' : 'Отметить для изучения'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Удалить из словаря', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onTap: () {
        WordSheet.show(
          context,
          word: item.originalForm.isNotEmpty ? item.originalForm : item.lemma,
          cleanWord: item.lemma,
          contextSentence: item.contextSentence,
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Слов пока нет',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Открывайте тексты или YouTube видео в библиотеке и нажимайте на любые незнакомые слова, чтобы добавлять их в словарь.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
