import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
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
      body: Column(
        children: [
          const _EmailVerificationBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [HomeScreen(), GroupsScreen(), SettingsScreen()],
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

class _EmailVerificationBanner extends ConsumerStatefulWidget {
  const _EmailVerificationBanner();

  @override
  ConsumerState<_EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<_EmailVerificationBanner> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = ref.watch(emailVerifiedProvider);
    if (verified.value != false) return const SizedBox.shrink();

    return Material(
      color: context.palette.primary.withValues(alpha: 0.10),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: context.palette.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _sent
                      ? 'Verification email sent. Check your inbox.'
                      : 'Please verify your email address.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              _sending
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(onPressed: _resend, child: const Text('Resend')),
              IconButton(
                tooltip: "I've verified",
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(emailVerifiedProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
