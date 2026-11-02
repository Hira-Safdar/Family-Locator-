import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/utils/password_validator.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _termsError;
  String? _serverError;
  bool _locked = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreed = false;

  String? _validateEmail(String email, AppLocalizations strings) {
    final valid = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$').hasMatch(email);
    return valid ? null : strings.validEmail;
  }

  String? _validatePassword(String password) =>
      PasswordValidator.validate(password);

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final nameError = name.isEmpty ? strings.nameEmpty : null;
    final emailError = _validateEmail(email, strings);
    final passwordError = password.isEmpty
        ? strings.passwordEmpty
        : _validatePassword(password);
    final confirmError = _confirmController.text.isEmpty
        ? strings.confirmPasswordPrompt
        : (_confirmController.text != password
              ? strings.passwordsMismatch
              : null);
    final termsError = _agreed ? null : strings.termsContinue;
    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null ||
        termsError != null) {
      setState(() {
        _nameError = nameError;
        _emailError = emailError;
        _passwordError = passwordError;
        _confirmError = confirmError;
        _termsError = termsError;
        _serverError = null;
      });
      return;
    }

    setState(() {
      _locked = true;
      _serverError = null;
    });

    final controller = ref.read(authControllerProvider.notifier);
    try {
      await controller.signUp(name: name, email: email, password: password);
      if (mounted) context.go('/home');
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.createAccount,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameController,
                  enabled: !_locked,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                    errorText: _nameError,
                  ),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  enabled: !_locked,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                  ),
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  enabled: !_locked,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    errorText: _passwordError,
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _confirmController,
                  enabled: !_locked,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: strings.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    errorText: _confirmError,
                  ),
                  onChanged: (_) {
                    if (_confirmError != null) {
                      setState(() => _confirmError = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  value: _agreed,
                  onChanged: _locked
                      ? null
                      : (value) => setState(() {
                          _agreed = value ?? false;
                          if (_agreed) _termsError = null;
                        }),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(strings.termsAgreement),
                  subtitle: _termsError == null
                      ? null
                      : Text(
                          _termsError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _serverError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                CustomButton(
                  label: strings.signUp,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(strings.alreadyAccount),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(strings.signIn),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
