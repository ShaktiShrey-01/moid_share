import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/auth_providers.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth.dart';
import '../widgets/auth_validators.dart';

/// Email/password sign-in. On success the router guard redirects to home, so
/// this screen never navigates manually.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(
          _email.text.trim(),
          _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text('Welcome back', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to continue to Moid-Share.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (state.errorMessage != null) ...[
                AuthErrorBanner(message: state.errorMessage!),
                const SizedBox(height: AppSpacing.lg),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !state.submitting,
                      validator: AuthValidators.email,
                      serverErrors: state.fieldErrors['email'],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthTextField(
                      controller: _password,
                      label: 'Password',
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !state.submitting,
                      validator: AuthValidators.loginPassword,
                      serverErrors: state.fieldErrors['password'],
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: state.submitting
                      ? null
                      : () => context.pushNamed(RouteNames.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: state.submitting ? null : _submit,
                child: state.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const OrDivider(),
              const SizedBox(height: AppSpacing.lg),
              GoogleSignInButton(
                enabled: !state.submitting,
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signInWithGoogle(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: state.submitting
                        ? null
                        : () => context.pushNamed(RouteNames.signup),
                    child: const Text('Create one'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
