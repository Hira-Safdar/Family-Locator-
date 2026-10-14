import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  String? _passwordError;
  String? _emailError;
  String? _serverError;
  bool _showPassword = false;
  bool _locked = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String email) {
    final valid = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email';
  }

  Future<void> _submit(String currentEmail) async {
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    final passwordError = password.isEmpty
        ? 'Enter your current password'
        : null;
    final emailError = _validateEmail(email);
    final same = email.toLowerCase() == currentEmail.toLowerCase()
        ? 'This is already your email'
        : null;

    if (passwordError != null || emailError != null || same != null) {
      setState(() {
        _passwordError = passwordError;
        _emailError = emailError ?? same;
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
          .changeEmail(currentPassword: password, newEmail: email);
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Check your inbox'),
          content: Text(
            'We sent a verification link to $email. '
            'Your email changes after you open that link.',
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
    final uid = ref.watch(authStateProvider).value;
    final currentEmail = uid == null
        ? ''
        : ref.watch(userProfileProvider(uid)).value?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Text(
            'For your security, enter your current password, then your new email address.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          if (currentEmail.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.email_outlined, color: AppColors.textLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current: $currentEmail',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            enabled: !_locked,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Current password',
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _passwordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            enabled: !_locked,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'New email',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _emailError,
            ),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            onSubmitted: (_) => _submit(currentEmail),
          ),
          if (_serverError != null) ...[
            const SizedBox(height: 16),
            Text(
              _serverError!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 28),
          CustomButton(
            label: 'Update Email',
            isLoading: _locked,
            onPressed: () => _submit(currentEmail),
          ),
        ],
      ),
    );
  }
}
