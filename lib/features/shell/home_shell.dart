import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  StreamSubscription<RemoteMessage>? _tapSub;

  @override
  void initState() {
    super.initState();
    _registerPushToken();
    _listenNotificationTaps();
  }

  void _listenNotificationTaps() {
    final messaging = ref.read(messagingServiceProvider);
    _tapSub = messaging.onMessageOpenedApp.listen(_openNotification);
    messaging.getInitialMessage().then((message) {
      if (message != null) _openNotification(message);
    });
  }

  void _openNotification(RemoteMessage message) {
    if (!mounted) return;
    final data = message.data;
    if (data['type'] != 'sos') return;
    final latitude = double.tryParse(data['latitude'] ?? '');
    final longitude = double.tryParse(data['longitude'] ?? '');
    final name = data['name'] ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (latitude == null || longitude == null) {
        context.push('/alerts');
        return;
      }
      context.push(
        Uri(
          path: '/alert-map',
          queryParameters: {
            'lat': '$latitude',
            'lng': '$longitude',
            'name': name,
          },
        ).toString(),
      );
    });
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
    _tapSub?.cancel();
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
