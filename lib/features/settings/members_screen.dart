import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
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
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? context.palette.error,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _leave(GroupModel group) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: strings.leaveGroupQuestion,
      message: strings.leaveGroupMessage(group.name),
      confirmLabel: strings.leave,
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
    final strings = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: strings.deleteGroupQuestion,
      message: strings.deleteGroupMessage(group.name),
      confirmLabel: strings.delete,
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
    final strings = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: strings.removeMemberQuestion,
      message: strings.removeMemberMessage(name, group.name),
      confirmLabel: strings.remove,
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
    final strings = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: strings.transferOwnershipQuestion,
      message: strings.transferOwnershipMessage(name, group.name),
      confirmLabel: strings.makeOwner,
      confirmColor: context.palette.primary,
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
    final strings = AppLocalizations.of(context);
    final role = memberIsOwner
        ? strings.groupOwner
        : (isSelf ? strings.youMember : strings.member);
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
              Text(role, style: TextStyle(color: context.palette.textLight)),
              const SizedBox(height: 8),
              Text(
                location == null
                    ? strings.noLocationShared
                    : 'Last seen ${DateFormatter.lastSeen(location.timestamp)}',
                style: TextStyle(color: context.palette.textLight),
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
                    label: Text(strings.viewOnMap),
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
    final strings = AppLocalizations.of(context);
    final groupsAsync = ref.watch(myGroupsStreamProvider);
    final selfUid = ref.watch(authStateProvider).value;
    final locations =
        ref.watch(groupMemberLocationsProvider(widget.groupId)).value ??
        const <String, LocationPoint>{};

    return Scaffold(
      appBar: AppBar(title: Text(strings.members)),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(strings.couldNotLoadMembers, textAlign: TextAlign.center),
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
            return Center(child: Text(strings.groupUnavailable));
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
                    style: TextStyle(
                      color: context.palette.error,
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
                      hintText: strings.searchMembers,
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
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text(strings.noMembersMatch)),
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
                          foregroundColor: context.palette.error,
                          side: BorderSide(color: context.palette.error),
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
                        label: Text(
                          isOwner ? strings.deleteGroupQuestion : strings.leave,
                        ),
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
            style: TextStyle(fontSize: 13, color: context.palette.textLight),
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
    final strings = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider(uid)).value;
    final shortId = uid.length >= 4
        ? uid.substring(uid.length - 4).toUpperCase()
        : uid.toUpperCase();
    final name = profile?.name ?? '${strings.member} $shortId';
    final showManage = canManage && !isSelf && !memberIsOwner;

    final subtitle = location == null
        ? (isSelf ? strings.youMember : strings.noLocationShared)
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
            _badge(context, strings.groupOwner),
          ] else if (isSelf) ...[
            const SizedBox(width: 8),
            _badge(context, strings.youMember),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: context.palette.textLight),
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
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'owner',
                        child: Text(strings.makeOwner),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          strings.remove,
                          style: TextStyle(color: context.palette.error),
                        ),
                      ),
                    ],
                  )
                : null),
    );
  }

  Widget _badge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.palette.primary,
        ),
      ),
    );
  }
}
