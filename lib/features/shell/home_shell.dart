import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/campaign_banner_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared_widgets/campaign_banner.dart';
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
      ref
          .read(campaignBannerProvider.notifier)
          .show(title: title, body: body);
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
        if (kDebugMode) debugPrint('FCM token: $token');
        await ref.read(authRepositoryProvider).saveFcmToken(uid, token);
      }
      _tokenSub = messaging.onTokenRefresh.listen((token) {
        if (kDebugMode) debugPrint('FCM token refreshed: $token');
        ref.read(authRepositoryProvider).saveFcmToken(uid, token);
      });
    } catch (_) {}
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
    final banner = ref.watch(campaignBannerProvider);
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [HomeScreen(), GroupsScreen(), SettingsScreen()],
          ),
          if (banner != null)
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CampaignBanner(
                    key: ValueKey('${banner.title}:${banner.body}'),
                    title: banner.title,
                    body: banner.body,
                    onDismiss: () =>
                        ref.read(campaignBannerProvider.notifier).dismiss(),
                  ),
                ),
              ),
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
