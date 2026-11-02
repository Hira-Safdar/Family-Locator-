import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

class UserSettings {
  final bool notificationsEnabled;
  final int refreshSeconds;
  final ThemeMode themeMode;
  final Locale locale;

  const UserSettings({
    required this.notificationsEnabled,
    required this.refreshSeconds,
    required this.themeMode,
    required this.locale,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    int? refreshSeconds,
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      refreshSeconds: refreshSeconds ?? this.refreshSeconds,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return UserSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      refreshSeconds: prefs.getInt('refreshSeconds') ?? 10,
      themeMode: _decodeThemeMode(prefs.getString('themeMode')),
      locale: _decodeLocale(prefs.getString('language')),
    );
  }

  void setNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    ref
        .read(sharedPreferencesProvider)
        .setBool('notificationsEnabled', enabled);
  }

  void setRefreshSeconds(int seconds) {
    state = state.copyWith(refreshSeconds: seconds);
    ref.read(sharedPreferencesProvider).setInt('refreshSeconds', seconds);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(sharedPreferencesProvider).setString('themeMode', mode.name);
  }

  void setLanguage(String language) {
    final locale = language == 'Urdu' ? const Locale('ur') : const Locale('en');
    state = state.copyWith(locale: locale);
    ref.read(sharedPreferencesProvider).setString('language', language);
  }

  static ThemeMode _decodeThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  static Locale _decodeLocale(String? value) {
    return value == 'Urdu' ? const Locale('ur') : const Locale('en');
  }
}

final settingsProvider = NotifierProvider<SettingsController, UserSettings>(
  SettingsController.new,
);
