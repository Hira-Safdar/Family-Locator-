import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/password_validator.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _serverError;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _locked = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    final currentError = current.isEmpty ? 'Enter your current password' : null;
    final newError = PasswordValidator.validate(next);
    final confirmError = confirm != next ? 'Passwords do not match' : null;

    if (currentError != null || newError != null || confirmError != null) {
      setState(() {
        _currentError = currentError;
        _newError = newError;
        _confirmError = confirmError;
        _serverError = null;
      });
      return;
    }

    setState(() {
      _locked = true;
      _serverError = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(currentPassword: current, newPassword: next);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Password changed'),
          content: const Text(
            'Use your new password the next time you sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Text(
            'For your security, enter your current password, then choose a new one.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.palette.textLight),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _currentController,
            enabled: !_locked,
            obscureText: !_showCurrent,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Current password',
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _currentError,
              suffixIcon: IconButton(
                icon: Icon(
                  _showCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _showCurrent = !_showCurrent),
              ),
            ),
            onChanged: (_) {
              if (_currentError != null) setState(() => _currentError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newController,
            enabled: !_locked,
            obscureText: !_showNew,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              errorText: _newError,
              suffixIcon: IconButton(
                icon: Icon(
                  _showNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _showNew = !_showNew),
              ),
            ),
            onChanged: (_) {
              if (_newError != null) setState(() => _newError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            enabled: !_locked,
            obscureText: !_showNew,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              errorText: _confirmError,
            ),
            onChanged: (_) {
              if (_confirmError != null) {
                setState(() => _confirmError = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          if (_serverError != null) ...[
            const SizedBox(height: 16),
            Text(
              _serverError!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.palette.error),
            ),
          ],
          const SizedBox(height: 28),
          CustomButton(
            label: 'Update Password',
            isLoading: _locked,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
