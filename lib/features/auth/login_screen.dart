import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/failure.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _serverError;
  bool _locked = false;
  bool _obscurePassword = true;

  String? _validateEmail(String email, AppLocalizations strings) {
    final valid = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$').hasMatch(email);
    return valid ? null : strings.validEmail;
  }

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = _validateEmail(email, strings);
    final passwordError = password.isEmpty ? strings.passwordEmpty : null;
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
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
      await controller.signIn(email: email, password: password);
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 72,
                  color: context.palette.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.palette.textLight,
                  ),
                ),
                const SizedBox(height: 32),
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
                  textInputAction: TextInputAction.done,
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
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(strings.forgotPassword),
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
                  label: strings.signIn,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(strings.noAccount),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text(strings.signUp),
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
