// Импорт пакета для локального хранения настроек
import 'package:shared_preferences/shared_preferences.dart';
// Импорт пакета для работы с .env файлами
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ключи для хранения настроек
class SettingsKeys {
  static const String apiKey = 'api_key';
  static const String baseUrl = 'base_url';
  static const String provider = 'provider'; // 'openrouter' | 'vsetgpt'
  static const String maxTokens = 'max_tokens';
  static const String temperature = 'temperature';
  static const String debug = 'debug';
  static const String logLevel = 'log_level';
}

/// Пресеты URL для провайдеров
class ProviderPresets {
  static const String openRouter = 'https://openrouter.ai/api/v1';
  static const String vsetgpt = 'https://api.vsetgpt.ru/v1';
}

/// Сервис для работы с настройками приложения
class SettingsService {
  static SharedPreferences? _prefs;

  /// Инициализация сервиса
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _storage {
    if (_prefs == null) {
      throw StateError('SettingsService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Получить значение с приоритетом: настройки пользователя > .env
  static String getString(String key, {String defaultValue = ''}) {
    final fromPrefs = _storage.getString(key);
    if (fromPrefs != null && fromPrefs.isNotEmpty) {
      return fromPrefs;
    }
    final envKey = _keyToEnv(key);
    return dotenv.env[envKey] ?? defaultValue;
  }

  static String? _keyToEnv(String key) {
    switch (key) {
      case SettingsKeys.apiKey:
        return 'OPENROUTER_API_KEY';
      case SettingsKeys.baseUrl:
        return 'BASE_URL';
      case SettingsKeys.maxTokens:
        return 'MAX_TOKENS';
      case SettingsKeys.temperature:
        return 'TEMPERATURE';
      case SettingsKeys.debug:
        return 'DEBUG';
      case SettingsKeys.logLevel:
        return 'LOG_LEVEL';
      default:
        return null;
    }
  }

  /// Сохранить строковое значение
  static Future<bool> setString(String key, String value) async {
    return _storage.setString(key, value);
  }

  /// Получить int
  static int getInt(String key, {int defaultValue = 1000}) {
    final fromPrefs = _storage.getInt(key);
    if (fromPrefs != null) return fromPrefs;
    final str = dotenv.env[_keyToEnv(key)];
    return int.tryParse(str ?? '') ?? defaultValue;
  }

  /// Сохранить int
  static Future<bool> setInt(String key, int value) async {
    return _storage.setInt(key, value);
  }

  /// Получить double
  static double getDouble(String key, {double defaultValue = 0.7}) {
    final fromPrefs = _storage.getDouble(key);
    if (fromPrefs != null) return fromPrefs;
    final str = dotenv.env[_keyToEnv(key)];
    return double.tryParse(str ?? '') ?? defaultValue;
  }

  /// Сохранить double
  static Future<bool> setDouble(String key, double value) async {
    return _storage.setDouble(key, value);
  }

  /// Получить bool
  static bool getBool(String key, {bool defaultValue = false}) {
    final fromPrefs = _storage.getBool(key);
    if (fromPrefs != null) return fromPrefs;
    final str = dotenv.env[_keyToEnv(key)];
    if (str == null) return defaultValue;
    return str.toLowerCase() == 'true' || str == '1';
  }

  /// Сохранить bool
  static Future<bool> setBool(String key, bool value) async {
    return _storage.setBool(key, value);
  }

  /// Удалить настройку (вернётся к .env или default)
  static Future<bool> remove(String key) async {
    return _storage.remove(key);
  }

  /// Очистить все пользовательские настройки
  static Future<void> clearAll() async {
    for (final key in [
      SettingsKeys.apiKey,
      SettingsKeys.baseUrl,
      SettingsKeys.provider,
      SettingsKeys.maxTokens,
      SettingsKeys.temperature,
      SettingsKeys.debug,
      SettingsKeys.logLevel,
    ]) {
      await _storage.remove(key);
    }
  }

  /// Проверить, есть ли сохранённые настройки
  static bool hasUserSettings() {
    return _storage.getString(SettingsKeys.apiKey) != null ||
        _storage.getString(SettingsKeys.baseUrl) != null;
  }
}
