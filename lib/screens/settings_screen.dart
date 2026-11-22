import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late TextEditingController _targetLangController;
  late TextEditingController _nativeLangController;

  bool _obscureApiKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  final List<Map<String, String>> _presets = [
    {
      'name': 'OpenAI',
      'url': 'https://api.openai.com/v1',
      'model': 'gpt-4o-mini',
    },
    {
      'name': 'OpenRouter',
      'url': 'https://openrouter.ai/api/v1',
      'model': 'meta-llama/llama-3.1-8b-instruct:free',
    },
    {
      'name': 'Groq',
      'url': 'https://api.groq.com/openai/v1',
      'model': 'llama-3.1-8b-instant',
    },
    {
      'name': 'DeepSeek',
      'url': 'https://api.deepseek.com',
      'model': 'deepseek-chat',
    },
    {
      'name': 'Ollama (Local)',
      'url': 'http://localhost:11434/v1',
      'model': 'llama3.2',
    },
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _modelController = TextEditingController(text: settings.model);
    _targetLangController = TextEditingController(text: settings.targetLanguage);
    _nativeLangController = TextEditingController(text: settings.nativeLanguage);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _targetLangController.dispose();
    _nativeLangController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _baseUrlController.text = preset['url']!;
      _modelController.text = preset['model']!;
    });
    final settings = context.read<SettingsProvider>();
    settings.updateBaseUrl(preset['url']!);
    settings.updateModel(preset['model']!);
  }

  Future<void> _testConnection() async {
    // Save current values first
    final settings = context.read<SettingsProvider>();
    await settings.updateApiKey(_apiKeyController.text);
    await settings.updateBaseUrl(_baseUrlController.text);
    await settings.updateModel(_modelController.text);

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final success = await settings.testConnection();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = success;
          _testResult = success
              ? 'Успешное подключение к LLM API!'
              : 'Ошибка подключения к серверу.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Ошибка: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: LLM API
          Text(
            'Настройки LLM (ИИ-переводчик)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Presets row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((preset) {
              return ActionChip(
                label: Text(preset['name']!),
                onPressed: () => _applyPreset(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // API Key
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            onChanged: (val) => settings.updateApiKey(val),
            decoration: InputDecoration(
              labelText: 'API Ключ (Bearer Token)',
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Base URL
          TextField(
            controller: _baseUrlController,
            onChanged: (val) => settings.updateBaseUrl(val),
            decoration: const InputDecoration(
              labelText: 'Base URL провайдера',
              hintText: 'https://api.openai.com/v1',
              prefixIcon: const Icon(Icons.cloud_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Model
          TextField(
            controller: _modelController,
            onChanged: (val) => settings.updateModel(val),
            decoration: const InputDecoration(
              labelText: 'Модель нейросети',
              hintText: 'gpt-4o-mini, deepseek-chat, llama-3.1-8b-instant...',
              prefixIcon: const Icon(Icons.smart_toy_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Test button
          FilledButton.tonalIcon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            label: Text(_isTesting ? 'Проверка связи...' : 'Проверить подключение'),
          ),

          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? Colors.green.withOpacity(0.15)
                    : theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _testSuccess ? Colors.green : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testSuccess
                            ? (theme.brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade900)
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 40),

          // Section: Languages
          Text(
            'Языковые параметры',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _targetLangController,
            onChanged: (val) => settings.updateTargetLanguage(val),
            decoration: const InputDecoration(
              labelText: 'Изучаемый язык',
              hintText: 'English, Spanish, German, French, Japanese...',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nativeLangController,
            onChanged: (val) => settings.updateNativeLanguage(val),
            decoration: const InputDecoration(
              labelText: 'Язык перевода (родной)',
              hintText: 'Russian, Spanish, etc.',
              prefixIcon: Icon(Icons.translate),
              border: OutlineInputBorder(),
            ),
          ),

          const Divider(height: 40),

          // Section: Interface
          Text(
            'Интерфейс и чтение',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Автопрокрутка субтитров'),
            subtitle: const Text('Следовать за речью во время воспроизведения видео'),
            value: settings.autoScroll,
            onChanged: (val) => settings.updateAutoScroll(val),
          ),

          ListTile(
            title: const Text('Тема оформления'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  settings.updateThemeMode(newMode);
                }
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Системная')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Светлая')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Тёмная')),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'LinguaLeap v1.0.0 • Cross-Platform Language Learning',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
