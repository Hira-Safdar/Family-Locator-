import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ad_units.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/group_categories.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/failure.dart';
import '../../data/services/ads_service.dart';
import '../../providers/group_provider.dart';
import '../../shared_widgets/custom_button.dart';
import '../../shared_widgets/native_ad_widget.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key, this.category = GroupCategories.custom});

  final String category;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  Timer? _debounce;
  String? _nameError;
  String? _serverError;
  bool _locked = false;
  bool _isDuplicate = false;
  List<String> _suggestions = const [];

  bool get _isCustom => widget.category == GroupCategories.custom;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (_nameError != null || _serverError != null || _isDuplicate) {
      setState(() {
        _nameError = null;
        _serverError = null;
        _isDuplicate = false;
        _suggestions = const [];
      });
    }
    if (value.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), _checkDuplicate);
  }

  Future<void> _checkDuplicate() async {
    if (!_isCustom) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || !mounted) return;

    final repo = ref.read(groupRepositoryProvider);
    try {
      final taken = await repo.isNameTaken(
        name: name,
        category: widget.category,
      );
      if (!mounted || _nameController.text.trim() != name) return;

      if (!taken) {
        if (_isDuplicate) {
          setState(() {
            _isDuplicate = false;
            _suggestions = const [];
            _nameError = null;
          });
        }
        return;
      }

      final suggestions = await repo.suggestNames(
        name: name,
        category: widget.category,
      );
      if (!mounted || _nameController.text.trim() != name) return;

      setState(() {
        _isDuplicate = true;
        _suggestions = suggestions;
        _nameError = '"$name" is already used in ${widget.category}.';
      });
    } catch (_) {
      if (!mounted || _nameController.text.trim() != name) return;
      if (_isDuplicate) {
        setState(() {
          _isDuplicate = false;
          _suggestions = const [];
          _nameError = null;
        });
      }
    }
  }

  void _applySuggestion(String suggestion) {
    _debounce?.cancel();
    _nameController.text = suggestion;
    setState(() {
      _nameError = null;
      _serverError = null;
      _isDuplicate = false;
      _suggestions = const [];
    });
  }

  Future<void> _submit() async {
    final name = _isCustom ? _nameController.text.trim() : widget.category;
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Group name cannot be empty';
        _serverError = null;
        _isDuplicate = false;
        _suggestions = const [];
      });
      return;
    }
    if (_isDuplicate) return;

    setState(() {
      _nameError = null;
      _serverError = null;
      _locked = true;
    });

    final repo = ref.read(groupRepositoryProvider);
    try {
      final taken = await repo.isNameTaken(
        name: name,
        category: widget.category,
      );
      if (taken) {
        final suggestions = await repo.suggestNames(
          name: name,
          category: widget.category,
        );
        if (!mounted) return;
        setState(() {
          _locked = false;
          _isDuplicate = true;
          _suggestions = suggestions;
          _nameError = '"$name" is already used in ${widget.category}.';
        });
        return;
      }

      final controller = ref.read(groupControllerProvider.notifier);
      final group = await controller.createGroup(
        name: name,
        category: widget.category,
      );
      if (mounted) {
        AdsService.instance.showInterstitialIfAllowed();
        context.go(
          '/invite?code=${group.inviteCode}'
          '&name=${Uri.encodeComponent(group.name)}',
        );
      }
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _locked = false;
        _serverError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locked = false;
        _serverError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupControllerProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: strings.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/choose-group');
            }
          },
        ),
        title: Text(strings.newGroup),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.group_add, size: 72, color: context.palette.primary),
              const SizedBox(height: 16),
              Text(
                'Create a group to start tracking each other',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: context.palette.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.category,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: context.palette.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _locked
                        ? null
                        : () => context.go('/choose-group'),
                    child: Text(strings.change),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isCustom)
                TextField(
                  controller: _nameController,
                  enabled: !_locked,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: strings.groupName,
                    prefixIcon: const Icon(Icons.group_outlined),
                    errorText: _nameError,
                  ),
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submit(),
                ),
              if (_isDuplicate && _suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Try one of these',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in _suggestions)
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: () => _applySuggestion(suggestion),
                      ),
                  ],
                ),
              ],
              if (_serverError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _serverError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                label: strings.createGroup,
                isLoading: state.isLoading || _locked,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              const NativeAdWidget(
                adUnitId: AdUnits.groupSetupNative,
                height: 96,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
