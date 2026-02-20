// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт сервиса настроек
import '../services/settings_service.dart';

/// Провайдер для управления настройками приложения
class SettingsProvider with ChangeNotifier {
  String get apiKey => SettingsService.getString(SettingsKeys.apiKey);
  String get baseUrl => SettingsService.getString(
        SettingsKeys.baseUrl,
        defaultValue: ProviderPresets.openRouter,
      );
  String get provider {
    final p = SettingsService.getString(SettingsKeys.provider);
    if (p.isNotEmpty) return p;
    return baseUrl.contains('vsetgpt') ? 'vsetgpt' : 'openrouter';
  }
  int get maxTokens => SettingsService.getInt(SettingsKeys.maxTokens, defaultValue: 1000);
  double get temperature =>
      SettingsService.getDouble(SettingsKeys.temperature, defaultValue: 0.7);
  bool get debug => SettingsService.getBool(SettingsKeys.debug, defaultValue: false);
  String get logLevel =>
      SettingsService.getString(SettingsKeys.logLevel, defaultValue: 'INFO');

  /// Установить API ключ
  Future<void> setApiKey(String value) async {
    await SettingsService.setString(SettingsKeys.apiKey, value);
    notifyListeners();
  }

  /// Установить провайдера и соответствующий base URL
  Future<void> setProvider(String providerName) async {
    await SettingsService.setString(SettingsKeys.provider, providerName);
    final url = providerName == 'vsetgpt'
        ? ProviderPresets.vsetgpt
        : ProviderPresets.openRouter;
    await SettingsService.setString(SettingsKeys.baseUrl, url);
    notifyListeners();
  }

  /// Установить base URL напрямую
  Future<void> setBaseUrl(String value) async {
    await SettingsService.setString(SettingsKeys.baseUrl, value);
    notifyListeners();
  }

  /// Установить max tokens
  Future<void> setMaxTokens(int value) async {
    await SettingsService.setInt(SettingsKeys.maxTokens, value);
    notifyListeners();
  }

  /// Установить temperature
  Future<void> setTemperature(double value) async {
    await SettingsService.setDouble(SettingsKeys.temperature, value);
    notifyListeners();
  }

  /// Установить debug
  Future<void> setDebug(bool value) async {
    await SettingsService.setBool(SettingsKeys.debug, value);
    notifyListeners();
  }

  /// Установить log level
  Future<void> setLogLevel(String value) async {
    await SettingsService.setString(SettingsKeys.logLevel, value);
    notifyListeners();
  }

  /// Очистить все настройки
  Future<void> clearAll() async {
    await SettingsService.clearAll();
    notifyListeners();
  }

  /// Проверить, настроен ли API
  bool get isConfigured => apiKey.isNotEmpty && baseUrl.isNotEmpty;
}
