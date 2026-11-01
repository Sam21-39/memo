import 'package:flutter/material.dart';

import '../../../../core/ui/memo_mark.dart';
import 'welcome_page.dart';

/// Artboard Onboarding-Permission: the primer before the OS asks.
class PermissionPrimerPage extends StatelessWidget {
  const PermissionPrimerPage({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      art: const EmptyRing(),
      title: 'Let Memō ring',
      paragraphs: const [
        'Alarms are notifications. The next screen is the phone asking you to '
            'allow them. Nothing else is asked for.',
        'On Android you will also be asked to allow exact alarms so a 7:00 '
            'reminder rings at 7:00, not 7:40.',
      ],
      actions: [
        ElevatedButton(
          onPressed: onContinue,
          child: const Text('Allow notifications'),
        ),
        OutlinedButton(onPressed: onSkip, child: const Text('Not now')),
      ],
    );
  }
}
