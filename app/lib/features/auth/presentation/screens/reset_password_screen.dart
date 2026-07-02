import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/auth_providers.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_validators.dart';

/// Sets a new password from an emailed reset [token] (delivered via deep link,
/// e.g. `moidshare://reset-password?token=...`).
///
/// If the token is missing/empty the screen explains how to get here rather
/// than showing a broken form.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(widget.token, _password.text);
    if (ok && mounted) {
      // Send the user to sign in with their new password.
      context.goNamed(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    if (widget.token.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reset password')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off_outlined,
                    size: 44, color: theme.colorScheme.error),
                const SizedBox(height: AppSpacing.lg),
                Text('Invalid reset link',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Open the link from your password-reset email to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.login),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Set a new password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Create a new password', style: theme.textTheme.headlineMedium),
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
                    controller: _password,
                    label: 'New password',
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !state.submitting,
                    validator: AuthValidators.password,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    controller: _confirm,
                    label: 'Confirm password',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    enabled: !state.submitting,
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: state.submitting ? null : _submit,
              child: state.submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}
