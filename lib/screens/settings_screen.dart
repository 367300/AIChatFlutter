// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера настроек
import '../providers/settings_provider.dart';
// Импорт провайдера чата (для обновления после смены настроек)
import '../providers/chat_provider.dart';
// Импорт сервиса настроек
import '../services/settings_service.dart';

/// Экран настроек провайдера и параметров приложения
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _maxTokensController;
  late TextEditingController _temperatureController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _maxTokensController =
        TextEditingController(text: settings.maxTokens.toString());
    _temperatureController =
        TextEditingController(text: settings.temperature.toString());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        foregroundColor: Colors.white,
        title: const Text(
          'Настройки провайдера',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Сбросить к значениям по умолчанию',
            onPressed: _showClearDialog,
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Провайдер'),
              _buildProviderSelector(settings),
              const SizedBox(height: 24),
              _buildSectionTitle('API ключ'),
              _buildApiKeyField(settings),
              const SizedBox(height: 24),
              _buildSectionTitle('Параметры API'),
              _buildBaseUrlField(settings),
              _buildMaxTokensField(settings),
              _buildTemperatureField(settings),
              const SizedBox(height: 24),
              _buildSectionTitle('Дополнительно'),
              _buildDebugSwitch(settings),
              _buildLogLevelSelector(settings),
              const SizedBox(height: 32),
              _buildSaveButton(settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProviderSelector(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text(
                'OpenRouter',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'openrouter.ai',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              value: 'openrouter',
              groupValue: settings.provider,
              activeColor: Colors.blue,
              onChanged: (v) async {
                if (v != null) {
                  await settings.setProvider(v);
                  _baseUrlController.text = settings.baseUrl;
                }
              },
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text(
                'VseGPT',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'api.vsetgpt.ru',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              value: 'vsetgpt',
              groupValue: settings.provider,
              activeColor: Colors.blue,
              onChanged: (v) async {
                if (v != null) {
                  await settings.setProvider(v);
                  _baseUrlController.text = settings.baseUrl;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField(SettingsProvider settings) {
    return TextField(
      controller: _apiKeyController,
      obscureText: _obscureApiKey,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Введите API ключ',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF333333),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureApiKey ? Icons.visibility : Icons.visibility_off,
            color: Colors.white54,
          ),
          onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
        ),
      ),
    );
  }

  Widget _buildBaseUrlField(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _baseUrlController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'https://openrouter.ai/api/v1',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMaxTokensField(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _maxTokensController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '1000',
          hintStyle: const TextStyle(color: Colors.white54),
          labelText: 'MAX_TOKENS',
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureField(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _temperatureController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '0.7',
          hintStyle: const TextStyle(color: Colors.white54),
          labelText: 'TEMPERATURE (0.0 - 1.0)',
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDebugSwitch(SettingsProvider settings) {
    return SwitchListTile(
      title: const Text(
        'DEBUG',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: const Text(
        'Режим отладки',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: settings.debug,
      activeThumbColor: Colors.blue,
      onChanged: (v) => settings.setDebug(v),
    );
  }

  Widget _buildLogLevelSelector(SettingsProvider settings) {
    const levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR'];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        initialValue:
            levels.contains(settings.logLevel) ? settings.logLevel : 'INFO',
        dropdownColor: const Color(0xFF333333),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'LOG_LEVEL',
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: levels
            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
            .toList(),
        onChanged: (v) {
          if (v != null) settings.setLogLevel(v);
        },
      ),
    );
  }

  Widget _buildSaveButton(SettingsProvider settings) {
    return ElevatedButton.icon(
      onPressed: () => _saveAndRefresh(settings),
      icon: const Icon(Icons.save, size: 20),
      label: const Text('Сохранить и обновить'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Future<void> _saveAndRefresh(SettingsProvider settings) async {
    await settings.setApiKey(_apiKeyController.text);
    await settings.setBaseUrl(_baseUrlController.text);
    final mt = int.tryParse(_maxTokensController.text);
    if (mt != null && mt > 0) await settings.setMaxTokens(mt);
    final temp = double.tryParse(_temperatureController.text);
    if (temp != null && temp >= 0 && temp <= 1) {
      await settings.setTemperature(temp);
    }

    if (!context.mounted) return;
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.refreshAfterSettingsChange();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки сохранены'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Сбросить настройки?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все сохранённые настройки будут удалены. Будут использованы значения из .env или по умолчанию.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<SettingsProvider>().clearAll();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                setState(() {
                  _apiKeyController.text = '';
                  _baseUrlController.text = ProviderPresets.openRouter;
                  _maxTokensController.text = '1000';
                  _temperatureController.text = '0.7';
                });
              }
            },
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
