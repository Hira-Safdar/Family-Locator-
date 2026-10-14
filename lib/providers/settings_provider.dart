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

  const UserSettings({
    required this.notificationsEnabled,
    required this.refreshSeconds,
    required this.themeMode,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    int? refreshSeconds,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      refreshSeconds: refreshSeconds ?? this.refreshSeconds,
      themeMode: themeMode ?? this.themeMode,
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

  static ThemeMode _decodeThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, UserSettings>(
  SettingsController.new,
);
