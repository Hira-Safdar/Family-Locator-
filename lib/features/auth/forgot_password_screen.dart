import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/failure.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _serverError;
  bool _locked = false;
  bool _sent = false;

  String? _validateEmail(String email, AppLocalizations strings) {
    final valid = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$').hasMatch(email);
    return valid ? null : strings.validEmail;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final strings = AppLocalizations.of(context);
    final emailError = _validateEmail(email, strings);
    if (emailError != null) {
      setState(() {
        _emailError = emailError;
        _serverError = null;
      });
      return;
    }

    setState(() {
      _locked = true;
      _serverError = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _locked = false;
        _sent = true;
      });
    } on Failure catch (e) {
      setState(() {
        _locked = false;
        _serverError = e.message;
      });
    } catch (_) {
      setState(() {
        _locked = false;
        _serverError = strings.somethingWrong;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _sent ? _sentView(context) : _formView(context),
          ),
        ),
      ),
    );
  }

  Widget _formView(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset, size: 72, color: context.palette.primary),
        const SizedBox(height: 16),
        Text(
          strings.forgotPassword,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          strings.forgotSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.palette.textLight),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          enabled: !_locked,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: strings.email,
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
          ),
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        if (_serverError != null) ...[
          const SizedBox(height: 16),
          Text(
            _serverError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        CustomButton(
          label: strings.sendResetLink,
          isLoading: _locked,
          onPressed: _submit,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(strings.rememberedIt),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(strings.signIn),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sentView(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: context.palette.success,
        ),
        const SizedBox(height: 16),
        Text(
          strings.checkEmail,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a password reset link to ${_emailController.text.trim()}. '
          'Open it to choose a new password.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.palette.textLight),
        ),
        const SizedBox(height: 32),
        CustomButton(
          label: strings.backToSignIn,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
