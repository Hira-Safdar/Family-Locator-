import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Get notified when someone needs help'),
            value: settings.notificationsEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNotifications(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}