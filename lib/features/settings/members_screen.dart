import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../data/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../shared_widgets/profile_avatar.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String? _busyUid;
  String? _error;
  bool _actionBusy = false;

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _leave(GroupModel group) async {
    final confirmed = await _confirm(
      title: 'Leave group?',
      message:
          'You will stop sharing your location with "${group.name}" and leave the group.',
      confirmLabel: 'Leave',
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _actionBusy = true;
      _error = null;
    });
    try {
      await ref.read(groupRepositoryProvider).leaveGroup(group.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionBusy = false;
        _error = e is Failure
            ? e.message
            : 'Could not leave the group. Please try again.';
      });
    }
  }

  Future<void> _delete(GroupModel group) async {
    final confirmed = await _confirm(
      title: 'Delete group?',
      message:
          'This permanently deletes "${group.name}" for everyone. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _actionBusy = true;
      _error = null;
    });
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(group.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionBusy = false;
        _error = e is Failure
            ? e.message
            : 'Could not delete the group. Please try again.';
      });
    }
  }

  Future<void> _remove(GroupModel group, String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove $name from "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busyUid = uid;
      _error = null;
    });
    try {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(groupId: group.id, uid: uid);
      if (!mounted) return;
      setState(() => _busyUid = null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyUid = null;
        _error = e is Failure
            ? e.message
            : 'Could not remove member. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsStreamProvider);
    final selfUid = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text(
            'Could not load members. Please check your internet connection and try again.',
            textAlign: TextAlign.center,
          ),
        ),
        data: (groups) {
          GroupModel? group;
          for (final g in groups) {
            if (g.id == widget.groupId) {
              group = g;
              break;
            }
          }
          if (group == null) {
            return const Center(
              child: Text('This group is no longer available.'),
            );
          }
          final isOwner = group.ownerId == selfUid;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _header(context, group),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              for (final uid in group.memberIds)
                _MemberTile(
                  uid: uid,
                  memberIsOwner: group.ownerId == uid,
                  isSelf: uid == selfUid,
                  canManage: isOwner,
                  busy: _busyUid == uid,
                  onRemove: (memberUid, name) =>
                      _remove(group!, memberUid, name),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _actionBusy
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () =>
                            isOwner ? _delete(group!) : _leave(group!),
                        icon: Icon(
                          isOwner ? Icons.delete_outline : Icons.logout,
                        ),
                        label: Text(isOwner ? 'Delete group' : 'Leave group'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, GroupModel group) {
    final count = group.memberIds.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            '$count member${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.uid,
    required this.memberIsOwner,
    required this.isSelf,
    required this.canManage,
    required this.busy,
    required this.onRemove,
  });

  final String uid;
  final bool memberIsOwner;
  final bool isSelf;
  final bool canManage;
  final bool busy;
  final void Function(String uid, String name) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(uid)).value;
    final shortId = uid.length >= 4
        ? uid.substring(uid.length - 4).toUpperCase()
        : uid.toUpperCase();
    final name = profile?.name ?? 'Member $shortId';
    final showRemove = canManage && !isSelf && !memberIsOwner;

    return ListTile(
      leading: ProfileAvatar(
        name: name,
        photoUrl: profile?.photoUrl,
        radius: 24,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (memberIsOwner) ...[
            const SizedBox(width: 8),
            _badge('Owner'),
          ] else if (isSelf) ...[
            const SizedBox(width: 8),
            _badge('You'),
          ],
        ],
      ),
      subtitle: isSelf ? const Text('This is you') : null,
      trailing: showRemove
          ? (busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'Remove member',
                    icon: const Icon(
                      Icons.person_remove_outlined,
                      color: AppColors.error,
                    ),
                    onPressed: () => onRemove(uid, name),
                  ))
          : null,
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
