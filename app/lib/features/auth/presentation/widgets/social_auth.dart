import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// "or" divider used to separate primary auth from social auth.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// "Continue with Google" button. Presentation-only; the caller wires [onTap].
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onTap, this.enabled = true});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
      label: const Text('Continue with Google'),
    );
  }
}
