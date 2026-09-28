import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../providers/group_provider.dart';
import '../../shared_widgets/custom_button.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  String? _nameError;
  String? _serverError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Group name cannot be empty');
      return;
    }
    setState(() {
      _nameError = null;
      _serverError = null;
    });
    final controller = ref.read(groupControllerProvider.notifier);
    try {
      await controller.createGroup(name: name);
      if (mounted) context.go('/home');
    } on Failure catch (e) {
      setState(() => _serverError = e.message);
    } catch (_) {
      setState(() => _serverError = 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.group_add, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Create a group to start tracking each other',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Group name',
                  prefixIcon: const Icon(Icons.group_outlined),
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
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
                label: 'Create Group',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}