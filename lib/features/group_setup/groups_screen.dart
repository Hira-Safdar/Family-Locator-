import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/group_categories.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/invite_share.dart';
import '../../data/models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../shared_widgets/error_view.dart';
import '../../shared_widgets/loading_indicator.dart';

enum _GroupSort { newest, name, members }

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;
  _GroupSort _sort = _GroupSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GroupModel> _apply(List<GroupModel> groups) {
    final query = _query.trim().toLowerCase();
    final list = groups.where((group) {
      if (_category != null && group.category != _category) return false;
      if (query.isEmpty) return true;
      return group.name.toLowerCase().contains(query) ||
          group.inviteCode.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case _GroupSort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _GroupSort.members:
        list.sort((a, b) => b.memberIds.length.compareTo(a.memberIds.length));
      case _GroupSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  Future<void> _refresh() async {
    ref.invalidate(myGroupsStreamProvider);
    try {
      await ref.read(myGroupsStreamProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or code',
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _categoryChip('All', _category == null, () {
                        setState(() => _category = null);
                      }),
                      for (final category in GroupCategories.all)
                        _categoryChip(category, _category == category, () {
                          setState(() => _category = category);
                        }),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<_GroupSort>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort',
                initialValue: _sort,
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _GroupSort.newest,
                    child: Text('Newest first'),
                  ),
                  PopupMenuItem(
                    value: _GroupSort.name,
                    child: Text('Name (A-Z)'),
                  ),
                  PopupMenuItem(
                    value: _GroupSort.members,
                    child: Text('Most members'),
                  ),
                ],
              ),
            ],
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
              data: (all) {
                final list = _apply(all);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: all.isEmpty
                      ? const _ScrollableMessage(child: _EmptyState())
                      : list.isEmpty
                      ? const _ScrollableMessage(child: _NoMatches())
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: list.length,
                          itemBuilder: (context, i) =>
                              _GroupCard(group: list[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 72, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              'No matching groups',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or category filter.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final GroupModel group;

  Future<void> _showRename(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RenameGroupDialog(group: group),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = group.memberIds.length;
    final isOwner = ref.watch(authStateProvider).value == group.ownerId;

    return GestureDetector(
      onTap: () => context.push('/members?groupId=${group.id}'),
      child: Container(
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
                group.name.isEmpty ? '?' : group.name[0].toUpperCase(),
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
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Owner',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primary,
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          group.category,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => copyInviteCode(context, group.inviteCode),
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          letterSpacing: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _showRename(context, ref);
                } else if (value == 'share') {
                  shareInvite(
                    groupName: group.name,
                    inviteCode: group.inviteCode,
                  );
                } else if (value == 'qr') {
                  _showQr(context);
                }
              },
              itemBuilder: (context) => [
                if (isOwner)
                  const PopupMenuItem(value: 'edit', child: Text('Edit name')),
                const PopupMenuItem(value: 'share', child: Text('Share invite')),
                const PopupMenuItem(value: 'qr', child: Text('Show QR')),
              ],
            ),
          ],
        ),
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
                border: Border.all(color: Colors.black12, width: 2),
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

class _RenameGroupDialog extends ConsumerStatefulWidget {
  const _RenameGroupDialog({required this.group});

  final GroupModel group;

  @override
  ConsumerState<_RenameGroupDialog> createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends ConsumerState<_RenameGroupDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.group.name,
  );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Group name cannot be empty');
      return;
    }
    if (name == widget.group.name) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(groupControllerProvider.notifier).renameGroup(
            groupId: widget.group.id,
            name: name,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is Failure ? e.message : 'Could not rename the group.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit group name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            enabled: !_busy,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Group name'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
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
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
