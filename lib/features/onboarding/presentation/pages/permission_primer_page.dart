import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/ui/memo_mark.dart';
import 'welcome_page.dart';
import '../../../../l10n/l10n.dart';

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
      art: EmptyRing(),
      title: context.l10n.permTitle,
      paragraphs: [
        context.l10n.permBody1,
        if (Platform.isAndroid) context.l10n.permBody2,
      ],
      actions: [
        ElevatedButton(
          onPressed: onContinue,
          child: Text(context.l10n.permAllow),
        ),
        OutlinedButton(onPressed: onSkip, child: Text(context.l10n.permNotNow)),
      ],
    );
  }
}
