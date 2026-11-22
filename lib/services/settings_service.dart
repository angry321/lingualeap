import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String keyApiKey = 'settings_api_key';
  static const String keyBaseUrl = 'settings_base_url';
  static const String keyModel = 'settings_model';
  static const String keyTargetLanguage = 'settings_target_language';
  static const String keyNativeLanguage = 'settings_native_language';
  static const String keyAutoScroll = 'settings_auto_scroll';
  static const String keyFontSize = 'settings_font_size';
  static const String keyThemeMode = 'settings_theme_mode';

  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-4o-mini';
  static const String defaultTargetLang = 'English';
  static const String defaultNativeLang = 'Russian';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get apiKey => _prefs.getString(keyApiKey) ?? '';
  Future<bool> setApiKey(String value) => _prefs.setString(keyApiKey, value.trim());

  String get baseUrl => _prefs.getString(keyBaseUrl) ?? defaultBaseUrl;
  Future<bool> setBaseUrl(String value) => _prefs.setString(keyBaseUrl, value.trim());

  String get model => _prefs.getString(keyModel) ?? defaultModel;
  Future<bool> setModel(String value) => _prefs.setString(keyModel, value.trim());

  String get targetLanguage => _prefs.getString(keyTargetLanguage) ?? defaultTargetLang;
  Future<bool> setTargetLanguage(String value) => _prefs.setString(keyTargetLanguage, value.trim());

  String get nativeLanguage => _prefs.getString(keyNativeLanguage) ?? defaultNativeLang;
  Future<bool> setNativeLanguage(String value) => _prefs.setString(keyNativeLanguage, value.trim());

  bool get autoScroll => _prefs.getBool(keyAutoScroll) ?? true;
  Future<bool> setAutoScroll(bool value) => _prefs.setBool(keyAutoScroll, value);

  double get fontSize => _prefs.getDouble(keyFontSize) ?? 18.0;
  Future<bool> setFontSize(double value) => _prefs.setDouble(keyFontSize, value);

  ThemeMode get themeMode {
    final mode = _prefs.getString(keyThemeMode) ?? 'system';
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    return _prefs.setString(keyThemeMode, val);
  }
}
