import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/alert_record.dart';
import '../../data/models/group_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/group_provider.dart';

enum _AlertFilter { all, active, resolved }

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  _AlertFilter _filter = _AlertFilter.all;

  String _groupNameFor(List<GroupModel> groups, String groupId) {
    for (final g in groups) {
      if (g.id == groupId) return g.name;
    }
    return '';
  }

  List<AlertRecord> _apply(List<AlertRecord> alerts) {
    switch (_filter) {
      case _AlertFilter.active:
        return alerts.where((a) => a.resolvedAt == null).toList();
      case _AlertFilter.resolved:
        return alerts.where((a) => a.resolvedAt != null).toList();
      case _AlertFilter.all:
        return alerts;
    }
  }

  Future<void> _confirmClear() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _ClearAlertsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertHistoryProvider);
    final groups =
        ref.watch(myGroupsStreamProvider).value ?? const <GroupModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text(
            'Could not load alerts. Please check your internet connection and try again.',
            textAlign: TextAlign.center,
          ),
        ),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
              child: Text(
                'No alerts yet.\nSend an SOS and it will appear here.',
                textAlign: TextAlign.center,
              ),
            );
          }
          final alerts = _apply(all);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('All', _AlertFilter.all),
                    _filterChip('Active', _AlertFilter.active),
                    _filterChip('Resolved', _AlertFilter.resolved),
                  ],
                ),
              ),
              Expanded(
                child: alerts.isEmpty
                    ? const Center(child: Text('No alerts match this filter.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: alerts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _AlertCard(
                          alert: alerts[index],
                          groupName: _groupNameFor(
                            groups,
                            alerts[index].groupId,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, _AlertFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.groupName});

  final AlertRecord alert;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final resolved = alert.resolvedAt != null;
    final accentColor = resolved
        ? context.palette.success
        : context.palette.error;

    return InkWell(
      onTap: () => context.push(
        '/alert-map?lat=${alert.latitude}&lng=${alert.longitude}'
        '&name=${Uri.encodeComponent(alert.name)}',
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor,
              child: Icon(
                resolved ? Icons.check : Icons.sos,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.name.isEmpty ? 'Unknown member' : alert.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (groupName.isNotEmpty)
                    Text(
                      groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textLight,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent ${DateFormatter.lastSeen(alert.createdAt)}'
                    '${resolved ? ' · Resolved ${DateFormatter.lastSeen(alert.resolvedAt!)}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resolved ? 'Resolved' : 'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: context.palette.textLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearAlertsDialog extends ConsumerStatefulWidget {
  const _ClearAlertsDialog();

  @override
  ConsumerState<_ClearAlertsDialog> createState() => _ClearAlertsDialogState();
}

class _ClearAlertsDialogState extends ConsumerState<_ClearAlertsDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _clear() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(alertControllerProvider.notifier).clearHistory();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is Failure ? e.message : 'Could not clear alerts.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear alerts history?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This removes all of your past SOS alerts. This cannot be undone.',
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
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _clear,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Clear', style: TextStyle(color: context.palette.error)),
        ),
      ],
    );
  }
}
