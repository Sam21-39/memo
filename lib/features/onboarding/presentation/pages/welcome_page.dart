import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_mark.dart';
import '../../../../l10n/l10n.dart';

/// Artboard Main (Onboarding · Welcome).
class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      art: MemoMark(),
      title: context.l10n.welcomeTitle,
      paragraphs: [context.l10n.welcomeBody1, context.l10n.welcomeBody2],
      actions: [
        ElevatedButton(
          onPressed: onContinue,
          child: Text(context.l10n.commonContinue),
        ),
        TextButton(onPressed: onSkip, child: Text(context.l10n.commonSkip)),
      ],
    );
  }
}

/// Shared layout of the onboarding steps: art, display title, body
/// paragraphs, actions pinned to the bottom.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.art,
    required this.title,
    required this.paragraphs,
    required this.actions,
  });

  final Widget art;
  final String title;
  final List<String> paragraphs;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MemoSpace.gutter,
            0,
            MemoSpace.gutter,
            MemoSpace.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 120),
                    Align(alignment: Alignment.centerLeft, child: art),
                    const SizedBox(height: MemoSpace.space8),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: MemoType.display.copyWith(color: c.ink),
                      ),
                    ),
                    for (final p in paragraphs) ...[
                      const SizedBox(height: MemoSpace.space3),
                      Text(p, style: MemoType.body.copyWith(color: c.ink70)),
                    ],
                  ],
                ),
              ),
              for (final a in actions) ...[const SizedBox(height: 10), a],
            ],
          ),
        ),
      ),
    );
  }
}
