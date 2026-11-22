import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/material_item.dart';
import '../providers/app_providers.dart';

class ImportMaterialDialog extends StatefulWidget {
  const ImportMaterialDialog({super.key});

  static Future<MaterialItem?> show(BuildContext context) {
    return showDialog<MaterialItem>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ImportMaterialDialog(),
    );
  }

  @override
  State<ImportMaterialDialog> createState() => _ImportMaterialDialogState();
}

class _ImportMaterialDialogState extends State<ImportMaterialDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // YouTube tab controllers
  final TextEditingController _ytUrlController = TextEditingController();
  final TextEditingController _ytLangController = TextEditingController(text: 'en');

  // Text tab controllers
  final TextEditingController _textTitleController = TextEditingController();
  final TextEditingController _textContentController = TextEditingController();

  bool _isImporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ytUrlController.dispose();
    _ytLangController.dispose();
    _textTitleController.dispose();
    _textContentController.dispose();
    super.dispose();
  }

  Future<void> _handleYouTubeImport() async {
    final url = _ytUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Введите ссылку на YouTube видео');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final materialsProvider = context.read<MaterialsProvider>();
      final lang = _ytLangController.text.trim();

      final material = await materialsProvider.addYouTubeMaterial(
        url,
        preferredLang: lang.isNotEmpty ? lang : null,
      );

      if (mounted) {
        Navigator.of(context).pop(material);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _handleTextImport() async {
    final title = _textTitleController.text.trim();
    final text = _textContentController.text.trim();

    if (text.isEmpty) {
      setState(() => _errorMessage = 'Текст не может быть пустым');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final materialsProvider = context.read<MaterialsProvider>();
      final material = await materialsProvider.addTextMaterial(
        title: title.isEmpty ? 'Без названия' : title,
        text: text,
      );

      if (mounted) {
        Navigator.of(context).pop(material);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Добавить материал',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isImporting)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.smart_display_outlined), text: 'YouTube видео'),
                  Tab(icon: Icon(Icons.description_outlined), text: 'Свой текст / статья'),
                ],
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab views
              Expanded(
                child: _isImporting
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _tabController.index == 0
                                  ? 'Загрузка метаданных и субтитров YouTube...'
                                  : 'Обработка и токенизация текста...',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildYouTubeTab(),
                          _buildTextTab(),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // Bottom action buttons
              if (!_isImporting)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _handleYouTubeImport();
                        } else {
                          _handleTextImport();
                        }
                      },
                      icon: const Icon(Icons.download_done, size: 18),
                      label: const Text('Импортировать'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Вставьте ссылку на YouTube видео с субтитрами:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ytUrlController,
            decoration: const InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=... или youtu.be/...',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Язык субтитров (код ISO):',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ytLangController,
            decoration: const InputDecoration(
              hintText: 'en, es, de, fr, ja, ru (по умолчанию en)',
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Приложение автоматически извлечёт таймкоды и субтитры ролика. Приоритет отдаётся авторским субтитрам, затем автогенерируемым.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _textTitleController,
          decoration: const InputDecoration(
            labelText: 'Заголовок (необязательно)',
            hintText: 'Например: The Old Man and the Sea',
            prefixIcon: Icon(Icons.title),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _textContentController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              labelText: 'Вставьте текст для чтения',
              hintText: 'Статья, рассказ, диалог или фрагмент книги...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
