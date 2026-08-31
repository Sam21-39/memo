import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// memo Design System · Screens A · "Welcome" (onboarding 1/2).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  static const _points = [
    'No account, no cloud',
    'Daily, weekly or picked days',
    'Snooze 10m, 1h, tomorrow',
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
              Text('memo', style: theme.textTheme.labelSmall),
              const SizedBox(height: 20),
              Text(
                'Remind me\nabout that.',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 38,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'One line, one time. It lives on this phone, works with no '
                'signal, and rings even if the app is closed.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  for (var i = 0; i < _points.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: scheme.outline),
                          bottom: i == _points.length - 1
                              ? BorderSide(color: scheme.outline)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              (i + 1).toString().padLeft(2, '0'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _points[i],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  child: const Text('Get started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
