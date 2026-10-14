import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/group_model.dart';
import '../../data/models/location_point.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/member_locations_provider.dart';
import '../../shared_widgets/profile_avatar.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _busyUid;
  String? _error;
  bool _actionBusy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
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
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? AppColors.error,
            ),
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
    final confirmed = await _confirm(
      title: 'Remove member?',
      message: 'Remove $name from "${group.name}"?',
      confirmLabel: 'Remove',
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

  Future<void> _makeOwner(GroupModel group, String uid, String name) async {
    final confirmed = await _confirm(
      title: 'Transfer ownership?',
      message:
          '$name will become the owner of "${group.name}". You will stay a member and will no longer manage this group.',
      confirmLabel: 'Make owner',
      confirmColor: AppColors.primary,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busyUid = uid;
      _error = null;
    });
    try {
      await ref
          .read(groupRepositoryProvider)
          .transferOwnership(groupId: group.id, newOwnerId: uid);
      if (!mounted) return;
      setState(() => _busyUid = null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyUid = null;
        _error = e is Failure
            ? e.message
            : 'Could not transfer ownership. Please try again.';
      });
    }
  }

  void _openMember({
    required String name,
    required String? photoUrl,
    required bool memberIsOwner,
    required bool isSelf,
    required LocationPoint? location,
  }) {
    final role = memberIsOwner
        ? 'Group owner'
        : (isSelf ? 'You (member)' : 'Member');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(name: name, photoUrl: photoUrl, radius: 36),
              const SizedBox(height: 12),
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(role, style: const TextStyle(color: AppColors.textLight)),
              const SizedBox(height: 8),
              Text(
                location == null
                    ? 'No location shared yet'
                    : 'Last seen ${DateFormatter.lastSeen(location.timestamp)}',
                style: const TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              if (location != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        '/alert-map?lat=${location.latitude}'
                        '&lng=${location.longitude}'
                        '&name=${Uri.encodeComponent(name)}',
                      );
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View on map'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsStreamProvider);
    final selfUid = ref.watch(authStateProvider).value;
    final locations =
        ref.watch(groupMemberLocationsProvider(widget.groupId)).value ??
        const <String, LocationPoint>{};

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
          final query = _query.trim().toLowerCase();
          final visible = group.memberIds.where((uid) {
            if (query.isEmpty) return true;
            final name = ref.watch(userProfileProvider(uid)).value?.name ?? '';
            return name.toLowerCase().contains(query) ||
                uid.toLowerCase().contains(query);
          }).toList();

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
              if (group.memberIds.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search members',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No members match your search.')),
                ),
              for (final uid in visible)
                _MemberTile(
                  uid: uid,
                  memberIsOwner: group.ownerId == uid,
                  isSelf: uid == selfUid,
                  canManage: isOwner,
                  busy: _busyUid == uid,
                  location: locations[uid],
                  onRemove: (memberUid, name) =>
                      _remove(group!, memberUid, name),
                  onMakeOwner: (memberUid, name) =>
                      _makeOwner(group!, memberUid, name),
                  onOpen: (name, photoUrl) => _openMember(
                    name: name,
                    photoUrl: photoUrl,
                    memberIsOwner: group!.ownerId == uid,
                    isSelf: uid == selfUid,
                    location: locations[uid],
                  ),
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
    required this.location,
    required this.onRemove,
    required this.onMakeOwner,
    required this.onOpen,
  });

  final String uid;
  final bool memberIsOwner;
  final bool isSelf;
  final bool canManage;
  final bool busy;
  final LocationPoint? location;
  final void Function(String uid, String name) onRemove;
  final void Function(String uid, String name) onMakeOwner;
  final void Function(String name, String? photoUrl) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(uid)).value;
    final shortId = uid.length >= 4
        ? uid.substring(uid.length - 4).toUpperCase()
        : uid.toUpperCase();
    final name = profile?.name ?? 'Member $shortId';
    final showManage = canManage && !isSelf && !memberIsOwner;

    final subtitle = location == null
        ? (isSelf ? 'This is you' : 'No location shared yet')
        : 'Last seen ${DateFormatter.lastSeen(location!.timestamp)}';

    return ListTile(
      onTap: () => onOpen(name, profile?.photoUrl),
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
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textLight),
      ),
      trailing: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (showManage
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'owner') {
                        onMakeOwner(uid, name);
                      } else if (value == 'remove') {
                        onRemove(uid, name);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'owner',
                        child: Text('Make owner'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Remove member',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  )
                : null),
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
