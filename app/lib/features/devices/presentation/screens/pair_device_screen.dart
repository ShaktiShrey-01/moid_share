import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/device_providers.dart';
import '../../domain/entities/pairing_start.dart';

enum _PairMode { show, enter }

/// Pairs two devices of the same account: one device shows a code, the other
/// enters it. Both then trust each other for transfer/clipboard.
class PairDeviceScreen extends ConsumerStatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen> {
  _PairMode _mode = _PairMode.show;
  bool _busy = false;
  PairingStart? _pairing;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    final result =
        await ref.read(devicesControllerProvider.notifier).startPairing();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result case Success(:final value)) _pairing = value;
    });
    if (result case ResultFailure(:final failure)) _snack(failure.message);
  }

  Future<void> _complete() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _snack('Enter the 6-digit code');
      return;
    }
    setState(() => _busy = true);
    final result =
        await ref.read(devicesControllerProvider.notifier).completePairing(code);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        _snack('Devices paired');
        context.pop();
      case ResultFailure(:final failure):
        _snack(failure.message);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair device')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            SegmentedButton<_PairMode>(
              segments: const [
                ButtonSegment(
                  value: _PairMode.show,
                  label: Text('Show code'),
                  icon: Icon(Icons.qr_code_2),
                ),
                ButtonSegment(
                  value: _PairMode.enter,
                  label: Text('Enter code'),
                  icon: Icon(Icons.dialpad),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_mode == _PairMode.show)
              _ShowCode(busy: _busy, pairing: _pairing, onGenerate: _generate)
            else
              _EnterCode(
                busy: _busy,
                controller: _codeController,
                onSubmit: _complete,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShowCode extends StatelessWidget {
  const _ShowCode({
    required this.busy,
    required this.pairing,
    required this.onGenerate,
  });

  final bool busy;
  final PairingStart? pairing;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Generate a code on this device, then enter it on your other device '
          'to pair them.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (pairing != null)
          Column(
            children: [
              SelectableText(
                pairing!.code,
                style: theme.textTheme.displayMedium?.copyWith(
                  letterSpacing: 8,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Expires at ${TimeOfDay.fromDateTime(pairing!.expiresAt.toLocal()).format(context)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        FilledButton(
          onPressed: busy ? null : onGenerate,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(pairing == null ? 'Generate code' : 'Generate new code'),
        ),
      ],
    );
  }
}

class _EnterCode extends StatelessWidget {
  const _EnterCode({
    required this.busy,
    required this.controller,
    required this.onSubmit,
  });

  final bool busy;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Enter the 6-digit code shown on your other device.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextField(
          controller: controller,
          enabled: !busy,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 8),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Pair'),
        ),
      ],
    );
  }
}
