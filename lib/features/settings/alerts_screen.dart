import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/alert_record.dart';
import '../../data/models/group_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/group_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  String _groupNameFor(List<GroupModel> groups, String groupId) {
    for (final g in groups) {
      if (g.id == groupId) return g.name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertHistoryProvider);
    final groups = ref.watch(myGroupsStreamProvider).value ?? const <GroupModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts History')),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Could not load alerts. Please check your internet connection and try again.'),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                'No alerts yet.\nSend an SOS and it will appear here.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _AlertCard(
              alert: alerts[index],
              groupName: _groupNameFor(groups, alerts[index].groupId),
            ),
          );
        },
      ),
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
    final accentColor = resolved ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Sent ${DateFormatter.lastSeen(alert.createdAt)}'
                  '${resolved ? ' · Resolved ${DateFormatter.lastSeen(alert.resolvedAt!)}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
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
        ],
      ),
    );
  }
}