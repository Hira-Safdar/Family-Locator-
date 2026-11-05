import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/ad_units.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/failure.dart';
import '../../data/services/ads_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared_widgets/profile_avatar.dart';
import '../../shared_widgets/native_ad_widget.dart';

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

  String _locationLabel(AppLocalizations strings) {
    if (_always.isGranted) return strings.alwaysAllowed;
    if (_whenInUse.isGranted) return strings.whileUsing;
    if (_whenInUse.isPermanentlyDenied) return strings.denied;
    return strings.notAllowed;
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

  String _intervalLabel(int seconds, AppLocalizations strings) => seconds >= 60
      ? strings.everyMinutes(seconds ~/ 60)
      : strings.everySeconds(seconds);

  Future<void> _showRefreshSheet() async {
    final strings = AppLocalizations.of(context);
    final current = ref.read(settingsProvider).refreshSeconds;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in _intervals)
              ListTile(
                title: Text(_intervalLabel(option, strings)),
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
        return AppLocalizations.of(context).light;
      case ThemeMode.dark:
        return AppLocalizations.of(context).dark;
      default:
        return AppLocalizations.of(context).systemDefault;
    }
  }

  Future<void> _pickThemeMode(ThemeMode current) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(AppLocalizations.of(context).appearanceTitle),
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
    final strings = AppLocalizations.of(context);
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.about),
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
            Text(strings.aboutDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.close),
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
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _profileHeader(context),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: NativeAdWidget(adUnitId: AdUnits.settingsNative, height: 96),
          ),
          _sectionHeader(context, strings.managePermissions),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(strings.locationPermission),
            subtitle: Text(_locationLabel(strings)),
            trailing: Icon(_locationIcon, color: _locationColor),
            onTap: openAppSettings,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(strings.appearance),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AdsService.instance.registerInteraction();
              _pickThemeMode(settings.themeMode);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(strings.notifications),
            subtitle: Text(strings.sosAlerts),
            value: settings.notificationsEnabled,
            onChanged: (enabled) {
              AdsService.instance.registerInteraction();
              _setNotifications(enabled);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(strings.privacyControls),
            subtitle: Text(strings.pauseSharing),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AdsService.instance.registerInteraction();
              context.push('/privacy');
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          _sectionHeader(context, strings.general),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(strings.locationRefresh),
            subtitle: Text(_intervalLabel(settings.refreshSeconds, strings)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AdsService.instance.registerInteraction();
              _showRefreshSheet();
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(strings.alertsHistory),
            subtitle: Text(strings.pastSos),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AdsService.instance.registerInteraction();
              context.push('/alerts');
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(strings.changeEmail),
            subtitle: Text(strings.updateEmailSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-email'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text(strings.changePassword),
            subtitle: Text(strings.updatePasswordSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-password'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.delete_outline, color: context.palette.error),
            title: Text(
              strings.deleteProfile,
              style: TextStyle(color: context.palette.error),
            ),
            onTap: _confirmDelete,
          ),

          _sectionHeader(context, strings.others),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(strings.share),
            enabled: AppConfig.appLink.isNotEmpty,
            onTap: _shareApp,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: Text(strings.rateUs),
            enabled: AppConfig.playStoreUrl.isNotEmpty,
            onTap: () => _launch(AppConfig.playStoreUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text(strings.feedback),
            enabled: AppConfig.feedbackEmail.isNotEmpty,
            onTap: () => _launch('mailto:${AppConfig.feedbackEmail}'),
          ),

          _sectionHeader(context, strings.aboutSection),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(strings.helpSupport),
            enabled: AppConfig.feedbackEmail.isNotEmpty,
            onTap: () => _launch('mailto:${AppConfig.feedbackEmail}'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(strings.termsService),
            enabled: AppConfig.termsUrl.isNotEmpty,
            onTap: () => _launch(AppConfig.termsUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(strings.privacyPolicy),
            enabled: AppConfig.privacyPolicyUrl.isNotEmpty,
            onTap: () => _launch(AppConfig.privacyPolicyUrl),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.about),
            subtitle: Text(strings.aboutDetails),
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
              label: Text(strings.logout),
            ),
          ),
          const SizedBox(height: 16),
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
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.logoutQuestion),
      content: Text(strings.logoutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            strings.logout,
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
        _error = e is Failure
            ? e.message
            : AppLocalizations.of(context).couldNotDeleteProfile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.deleteProfileQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.deleteProfileMessage),
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
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  strings.delete,
                  style: TextStyle(color: context.palette.error),
                ),
        ),
      ],
    );
  }
}
