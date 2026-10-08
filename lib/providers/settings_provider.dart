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

  const UserSettings({
    required this.notificationsEnabled,
    required this.refreshSeconds,
  });

  UserSettings copyWith({bool? notificationsEnabled, int? refreshSeconds}) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      refreshSeconds: refreshSeconds ?? this.refreshSeconds,
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
}

final settingsProvider =
NotifierProvider<SettingsController, UserSettings>(SettingsController.new);