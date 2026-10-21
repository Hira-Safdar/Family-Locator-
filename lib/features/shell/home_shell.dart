import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
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
  String _campaignTitle = '';
  String _campaignBody = '';
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _tapSub;
  StreamSubscription<RemoteMessage>? _messageSub;

  @override
  void initState() {
    super.initState();
    _registerPushToken();
    _listenNotificationTaps();
    _listenCampaigns();
  }

  void _listenCampaigns() {
    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] != 'campaign') return;
      if (!ref.read(settingsProvider).notificationsEnabled) return;
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      if (title.isEmpty && body.isEmpty) return;
      ref
          .read(notificationServiceProvider)
          .showCampaign(title: title, body: body);
      if (!mounted) return;
      setState(() {
        _campaignTitle = title;
        _campaignBody = body;
      });
    });
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

  Widget _campaignBanner() {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign_outlined, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _campaignTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_campaignBody.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _campaignBody,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _campaignTitle = '';
                _campaignBody = '';
              }),
              icon: const Icon(Icons.close),
              iconSize: 20,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    _tapSub?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [HomeScreen(), GroupsScreen(), SettingsScreen()],
          ),
          if (_campaignTitle.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _campaignBanner(),
            ),
        ],
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
