import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSettings {
  final bool notificationsEnabled;

  const UserSettings({required this.notificationsEnabled});

  UserSettings copyWith({bool? notificationsEnabled}) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    return const UserSettings(notificationsEnabled: true);
  }

  void setNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, UserSettings>(SettingsController.new);