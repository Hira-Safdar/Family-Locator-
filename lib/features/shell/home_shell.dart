import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../group_setup/groups_screen.dart';
import '../home_map/home_map_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  StreamSubscription<String>? _tokenSub;

  @override
  void initState() {
    super.initState();
    _registerPushToken();
  }

  Future<void> _registerPushToken() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final messaging = ref.read(messagingServiceProvider);
    try {
      final token = await messaging.register();
      if (token != null && token.isNotEmpty) {
        await ref.read(authRepositoryProvider).saveFcmToken(uid, token);
      }
      _tokenSub = messaging.onTokenRefresh.listen((token) {
        ref.read(authRepositoryProvider).saveFcmToken(uid, token);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), GroupsScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
