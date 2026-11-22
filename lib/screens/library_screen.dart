import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/material_item.dart';
import '../providers/app_providers.dart';
import 'import_material_dialog.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialsProvider>().loadMaterials();
    });
  }

  Future<void> _openImportDialog() async {
    final newMaterial = await ImportMaterialDialog.show(context);
    if (newMaterial != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ReaderScreen(material: newMaterial),
        ),
      );
    }
  }

  Future<void> _confirmDelete(MaterialItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить материал?'),
        content: Text('Вы действительно хотите удалить "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null && mounted) {
      await context.read<MaterialsProvider>().deleteMaterial(item.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Материал "${item.title}" удален')),
      );
    }
  }

  void _addSampleMaterial() async {
    const sampleText =
        "The quick brown fox jumps over the lazy dog. Reading authentic foreign texts is one of the most effective ways to acquire natural vocabulary and grammar patterns. Whenever you encounter an unfamiliar expression or phrasal verb, you can tap it to receive a detailed linguistic breakdown powered by artificial intelligence. With regular spaced repetition reviews, words smoothly transition from active learning into your long-term memory.";
    await context.read<MaterialsProvider>().addTextMaterial(
          title: 'Welcome to LinguaLeap (Demo)',
          text: sampleText,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Библиотека',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MaterialsProvider>().loadMaterials(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openImportDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: Consumer<MaterialsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.materials.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMaterials(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: provider.materials.length,
              itemBuilder: (context, index) {
                final item = provider.materials[index];
                return _buildMaterialCard(item, theme);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(MaterialItem item, ThemeData theme) {
    final isYouTube = item.isYouTube;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(item.createdAt),
    );
    final segmentsCount = item.segments.length;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ReaderScreen(material: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon / Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isYouTube ? Colors.red.shade100 : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isYouTube ? Icons.smart_display : Icons.article,
                  color: isYouTube ? Colors.red.shade700 : theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isYouTube ? 'YouTube' : 'Текст',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$segmentsCount сегм.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.grey,
                tooltip: 'Удалить',
                onPressed: () => _confirmDelete(item),
              ),
            ],
          ),
        ),
      ),
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
              Icons.auto_stories_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Библиотека пуста',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Добавьте видео с YouTube или вставьте любой текст для интерактивного чтения с умным переводом слов.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _openImportDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить материал'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _addSampleMaterial,
                  child: const Text('Загрузить демо-текст'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
