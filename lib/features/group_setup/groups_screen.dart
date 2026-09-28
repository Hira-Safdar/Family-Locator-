import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../data/models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../shared_widgets/error_view.dart';
import '../../shared_widgets/loading_indicator.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/create-group'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/join-group'),
                    icon: const Icon(Icons.input),
                    label: const Text('Join'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: groups.when(
              loading: () => const LoadingIndicator(),
              error: (e, st) => ErrorView(
                message: e is Failure
                    ? e.message
                    : 'Something went wrong loading your groups.',
              ),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Text('No groups yet.\nCreate or join one with a code.'),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final group = list[i];
                        return ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(group.name),
                          subtitle: Text('Invite code: ${group.inviteCode}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${group.memberIds.length} members',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_2),
                                onPressed: () => _showQr(context, group),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQr(BuildContext context, GroupModel group) {
    final qrCode = QrCode.fromData(
      data: group.inviteCode,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.qr_code_2, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Invite QR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryContainer, width: 2),
              ),
              child: CustomPaint(
                painter: QrPainter.withQr(qr: qrCode, gapless: true),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              group.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                group.inviteCode,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}