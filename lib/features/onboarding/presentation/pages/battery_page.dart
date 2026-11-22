import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../reminders/presentation/widgets/section_card.dart';
import 'welcome_page.dart';

const _autostartMakers = {
  'xiaomi',
  'redmi',
  'poco',
  'vivo',
  'oppo',
  'realme',
  'oneplus',
};

/// Android step 3: let the OS keep Memō alive so alarms are not cut off.
class BatteryPage extends StatelessWidget {
  const BatteryPage({
    super.key,
    required this.maker,
    required this.onOpen,
    required this.onDone,
    required this.onSkip,
  });

  final String maker;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final steps = [
      l.onbBatteryStep1,
      if (_autostartMakers.contains(maker.toLowerCase())) l.onbBatteryStep2,
    ];
    return OnboardingScaffold(
      art: Text(
        l.onbStep3,
        style: MemoType.labelMedium.copyWith(color: c.ink70),
      ),
      title: l.onbBatteryTitle,
      paragraphs: [l.onbBatteryBody],
      body: SectionCard(
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.all(MemoSpace.space4),
              child: Text(
                s,
                style: MemoType.bodyLarge.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
      actions: [
        ElevatedButton(onPressed: onOpen, child: Text(l.healthOpenBattery)),
        OutlinedButton(onPressed: onDone, child: Text(l.onbDidThis)),
        TextButton(onPressed: onSkip, child: Text(l.onbSkipRisk)),
      ],
    );
  }
}
