import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../providers/location_provider.dart';

class PrivacyControlsScreen extends ConsumerStatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  ConsumerState<PrivacyControlsScreen> createState() =>
      _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState
    extends ConsumerState<PrivacyControlsScreen> {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear location history?'),
        content: const Text(
          'This removes your latest saved location from the map. '
          'Your friends will stop seeing your pin until you share again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
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
        _error = e is Failure
            ? e.message
            : 'Could not clear your location history.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharing = ref.watch(isSharingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Controls')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeader(context, 'Sharing'),
          SwitchListTile(
            secondary: const Icon(Icons.my_location),
            title: const Text('Share my location'),
            subtitle: Text(
              sharing
                  ? 'Your location updates are live'
                  : 'Location sharing is paused',
            ),
            value: sharing,
            onChanged: (v) => _toggleSharing(v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          _sectionHeader(context, 'Location History'),
          ListTile(
            enabled: !_clearing,
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Clear my location history'),
            subtitle: Text(
              _clearing
                  ? 'Clearing...'
                  : 'Removes your saved location from the map',
            ),
            trailing: _clearing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _clearHistory,
          ),
          if (_cleared) ...[
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Location history cleared.',
                style: TextStyle(color: AppColors.success, fontSize: 13),
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
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
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}