import 'package:flutter/material.dart';

import '../../../../core/ui/memo_mark.dart';
import 'welcome_page.dart';
import '../../../../l10n/strings.dart';

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
      title: S.permTitle,
      paragraphs: const [S.permBody1, S.permBody2],
      actions: [
        ElevatedButton(onPressed: onContinue, child: const Text(S.permAllow)),
        OutlinedButton(onPressed: onSkip, child: const Text(S.permNotNow)),
      ],
    );
  }
}
