import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// memo Design System · Screens A · "Permission primer" (onboarding 2/2).
class PermissionPrimerPage extends StatelessWidget {
  const PermissionPrimerPage({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  static const _uses = [
    'Ringing at the time you chose',
    'Done and Snooze buttons on the alert',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Before the system asks', style: theme.textTheme.labelSmall),
              const SizedBox(height: 18),
              Text(
                'iOS will ask to send you notifications. That is the alarm.',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 30,
                  height: 1.14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Without it a reminder can be saved but never heard. Nothing '
                'is sent anywhere — the phone schedules it locally.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(color: scheme.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What we use it for',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 10),
                    for (final use in _uses)
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '· ',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 15,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                use,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.secondary,
                    foregroundColor: scheme.onSecondary,
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Not now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
