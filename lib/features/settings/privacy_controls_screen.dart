import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/constants/app_strings.dart';
import '../../data/services/ads_service.dart';
import '../../providers/location_provider.dart';

class PrivacyControlsScreen extends ConsumerStatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  ConsumerState<PrivacyControlsScreen> createState() =>
      _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends ConsumerState<PrivacyControlsScreen> {
  bool _clearing = false;
  bool _cleared = false;
  String? _error;

  Future<void> _toggleSharing(bool on) async {
    setState(() => _error = null);
    try {
      final notifier = ref.read(locationControllerProvider.notifier);
      if (on) {
        await notifier.resume();
      } else {
        await notifier.stop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is Failure
            ? e.message
            : 'Could not update sharing. Please try again.';
      });
    }
  }

  Future<void> _clearHistory() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.clearHistoryQuestion),
        content: Text(strings.clearHistoryDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.palette.error),
            child: Text(strings.clearLocationHistory),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _clearing = true;
      _cleared = false;
      _error = null;
    });
    try {
      await ref.read(locationControllerProvider.notifier).clearHistory();
      if (!mounted) return;
      _cleared = true;
      setState(() => _clearing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clearing = false;
        _error = e is Failure ? e.message : strings.somethingWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharing = ref.watch(isSharingProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.privacyControls)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeader(context, strings.sharing),
          SwitchListTile(
            secondary: const Icon(Icons.my_location),
            title: Text(strings.shareMyLocation),
            subtitle: Text(
              sharing ? strings.locationLive : strings.sharingPaused,
            ),
            value: sharing,
            onChanged: (v) {
              AdsService.instance.registerInteraction();
              _toggleSharing(v);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          _sectionHeader(context, strings.locationHistory),
          ListTile(
            enabled: !_clearing,
            leading: Icon(Icons.delete_outline, color: context.palette.error),
            title: Text(strings.clearLocationHistory),
            subtitle: Text(
              _clearing ? strings.clearing : strings.removeSavedLocation,
            ),
            trailing: _clearing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: () {
              AdsService.instance.registerInteraction();
              _clearHistory();
            },
          ),
          if (_cleared) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                strings.locationHistoryCleared,
                style: TextStyle(color: context.palette.success, fontSize: 13),
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: context.palette.error, fontSize: 13),
              ),
            ),
          ],
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
}
