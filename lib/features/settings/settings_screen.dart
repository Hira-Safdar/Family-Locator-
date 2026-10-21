import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/ad_units.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/errors/failure.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared_widgets/banner_ad_widget.dart';
import '../../shared_widgets/profile_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus _whenInUse = PermissionStatus.denied;
  PermissionStatus _always = PermissionStatus.denied;

  static const List<int> _intervals = [5, 10, 30, 60];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final whenInUse = await Permission.locationWhenInUse.status;
    final always = await Permission.locationAlways.status;
    if (!mounted) return;
    setState(() {
      _whenInUse = whenInUse;
      _always = always;
    });
  }

  String get _locationLabel {
    if (_always.isGranted) return 'Always allowed';
    if (_whenInUse.isGranted) return 'While using the app';
    if (_whenInUse.isPermanentlyDenied) return 'Denied';
    return 'Not allowed';
  }

  Color get _locationColor {
    if (_always.isGranted || _whenInUse.isGranted) {
      return context.palette.success;
    }
    if (_whenInUse.isPermanentlyDenied) return context.palette.error;
    return context.palette.warning;
  }

  IconData get _locationIcon {
    if (_always.isGranted || _whenInUse.isGranted) return Icons.check_circle;
    if (_whenInUse.isPermanentlyDenied) return Icons.block;
    return Icons.warning_amber;
  }

  String _intervalLabel(int seconds) =>
      seconds >= 60 ? 'Every ${seconds ~/ 60} min' : 'Every $seconds seconds';

  Future<void> _showRefreshSheet() async {
    final current = ref.read(settingsProvider).refreshSeconds;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in _intervals)
              ListTile(
                title: Text(_intervalLabel(option)),
                trailing: option == current
                    ? Icon(Icons.check, color: context.palette.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;
    ref.read(settingsProvider.notifier).setRefreshSeconds(picked);
    await ref.read(locationControllerProvider.notifier).restart();
  }

  Future<void> _shareApp() async {
    final link = AppConfig.appLink;
    if (link.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: link));
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System default';
    }
  }

  Future<void> _pickThemeMode(ThemeMode current) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(mode),
              child: Row(
                children: [
                  Expanded(child: Text(_themeModeLabel(mode))),
                  if (mode == current)
                    Icon(Icons.check, color: context.palette.primary),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) {
      ref.read(settingsProvider.notifier).setThemeMode(selected);
    }
  }

  Future<void> _setNotifications(bool enabled) async {
    ref.read(settingsProvider.notifier).setNotifications(enabled);
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final repo = ref.read(authRepositoryProvider);
    final messaging = ref.read(messagingServiceProvider);
    try {
      if (enabled) {
        final token = await messaging.register();
        if (token != null && token.isNotEmpty) {
          await repo.saveFcmToken(uid, token);
        }
      } else {
        await repo.clearFcmToken(uid);
        await messaging.deleteToken();
      }
    } catch (_) {}
  }

  Future<void> _showAbout() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Locator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${info.version} (build ${info.buildNumber})',
              style: TextStyle(color: context.palette.textLight),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep your family connected and safe with live location '
              'sharing and SOS alerts.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteConfirmDialog(),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _profileHeader(context),
          _sectionHeader(context, 'Manage Permissions'),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Location Permission'),
            subtitle: Text(_locationLabel),
            trailing: Icon(_locationIcon, color: _locationColor),
            onTap: openAppSettings,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Appearance'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickThemeMode(settings.themeMode),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('SOS alerts and announcements'),
            value: settings.notificationsEnabled,
            onChanged: _setNotifications,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy Controls'),
            subtitle: const Text('Pause sharing or clear history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          _sectionHeader(context, 'General'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Location Refresh'),
            subtitle: Text(_intervalLabel(settings.refreshSeconds)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showRefreshSheet,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Alerts History'),
            subtitle: const Text('Past SOS alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/alerts'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Change Email'),
            subtitle: const Text('Update your account email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-email'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-password'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.delete_outline, color: context.palette.error),
            title: Text(
              'Delete Profile',
              style: TextStyle(color: context.palette.error),
            ),
            onTap: _confirmDelete,
          ),

          _sectionHeader(context, 'Others'),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            enabled: AppConfig.appLink.isNotEmpty,
            onTap: _shareApp,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('Rate us'),
            enabled: AppConfig.playStoreUrl.isNotEmpty,
            onTap: () => _launch(AppConfig.playStoreUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Feedback'),
            enabled: AppConfig.feedbackEmail.isNotEmpty,
            onTap: () => _launch('mailto:${AppConfig.feedbackEmail}'),
          ),

          _sectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            enabled: AppConfig.feedbackEmail.isNotEmpty,
            onTap: () => _launch('mailto:${AppConfig.feedbackEmail}'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            enabled: AppConfig.termsUrl.isNotEmpty,
            onTap: () => _launch(AppConfig.termsUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            enabled: AppConfig.privacyPolicyUrl.isNotEmpty,
            onTap: () => _launch(AppConfig.privacyPolicyUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('App version and details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.error,
                side: BorderSide(color: context.palette.error),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
          const SizedBox(height: 16),
          const BannerAdWidget(adUnitId: AdUnits.settingsBanner),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.palette.textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).value;
    final profile = uid == null
        ? null
        : ref.watch(userProfileProvider(uid)).value;
    final name = profile?.name ?? 'Your profile';
    final email = profile?.email ?? '';

    return InkWell(
      onTap: () => context.push('/view-profile'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ProfileAvatar(name: name, photoUrl: profile?.photoUrl, radius: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textLight),
          ],
        ),
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log out?'),
      content: const Text(
        'You will stop sharing your location until you sign in again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Log out',
            style: TextStyle(color: context.palette.error),
          ),
        ),
      ],
    );
  }
}

class _DeleteConfirmDialog extends ConsumerStatefulWidget {
  const _DeleteConfirmDialog();

  @override
  ConsumerState<_DeleteConfirmDialog> createState() =>
      _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends ConsumerState<_DeleteConfirmDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is Failure ? e.message : 'Could not delete profile.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Profile?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently removes your account, your location history and '
            'your membership in every group. This cannot be undone.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.palette.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Delete', style: TextStyle(color: context.palette.error)),
        ),
      ],
    );
  }
}
