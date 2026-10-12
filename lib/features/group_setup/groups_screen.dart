import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(title: const Text('All Groups')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.push('/choose-group'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create Group'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.push('/join-group'),
              icon: const Icon(Icons.login),
              label: const Text('Join a Group'),
            ),
          ),
          Expanded(
            child: groups.when(
              loading: () => LoadingIndicator(
                onRetry: () => ref.invalidate(myGroupsStreamProvider),
              ),
              error: (e, st) => ErrorView(
                message: e is Failure
                    ? e.message
                    : 'Something went wrong loading your groups. Please check your internet connection and try again.',
                onRetry: () => ref.invalidate(myGroupsStreamProvider),
              ),
              data: (list) => list.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: list.length,
                      itemBuilder: (context, i) =>
                          _GroupCard(group: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new group or join an existing one using an invite code.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final GroupModel group;

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: group.inviteCode));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Invite code ${group.inviteCode} copied')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final members = group.memberIds.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.background,
            child: Text(
              group.name.isEmpty
                  ? '?'
                  : group.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        group.category,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 15,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$members member${members == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _copyCode(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      group.inviteCode,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            letterSpacing: 3,
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Show QR',
            icon: const Icon(Icons.qr_code_2),
            color: AppColors.textLight,
            onPressed: () => _showQr(context),
          ),
        ],
      ),
    );
  }

  void _showQr(BuildContext context) {
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
              backgroundColor: AppColors.background,
              child: const Icon(Icons.qr_code_2, color: AppColors.textDark),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Invite QR')),
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
                border: Border.all(
                  color: Colors.black12,
                  width: 2,
                ),
              ),
              child: CustomPaint(
                painter: QrPainter.withQr(qr: qrCode, gapless: true),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              group.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                group.inviteCode,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
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
