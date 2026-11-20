import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/l10n.dart';
import 'settings_cubit.dart';

String healthStatusWord(AppLocalizations l, HealthStatus s) => switch (s) {
  HealthStatus.allowed => l.healthAllowed,
  HealthStatus.ok => l.healthOk,
  HealthStatus.fix => l.healthFix,
  HealthStatus.off => l.healthOff,
};

/// A word on a tint, never colour alone. Caution is only 3.8:1, so it draws
/// the border and the text stays ink.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.text});

  final HealthStatus status;

  /// Overrides the status word, e.g. "2 things to fix".
  final String? text;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final (Color color, Color ground, Color? border) = switch (status) {
      HealthStatus.allowed ||
      HealthStatus.ok => (c.ok, c.ok.withValues(alpha: .12), null),
      HealthStatus.fix => (c.ink, c.cautionSoft, c.caution),
      HealthStatus.off => (c.accentText, c.accentSoft, null),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: MemoSpace.space3,
        vertical: MemoSpace.space1,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ground,
        border: border == null ? null : Border.all(color: border),
        borderRadius: BorderRadius.circular(MemoRadius.pill),
      ),
      child: Text(
        text ?? healthStatusWord(context.l10n, status),
        style: MemoType.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class PermissionStatusRow extends StatelessWidget {
  const PermissionStatusRow({
    super.key,
    required this.title,
    required this.state,
    required this.status,
    this.onTap,
  });

  final String title;
  final String state;
  final HealthStatus status;

  /// Only used when the status is fix or off.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final tappable =
        onTap != null &&
        (status == HealthStatus.fix || status == HealthStatus.off);
    final label = '$title, $state, ${healthStatusWord(context.l10n, status)}';
    return Semantics(
      button: tappable,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: tappable ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoSpace.space4,
              vertical: MemoSpace.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: MemoType.bodyLarge.copyWith(
                          color: c.ink,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        state,
                        style: MemoType.body.copyWith(
                          color: c.ink70,
                          fontSize: 13,
                          height: 18 / 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MemoSpace.space2),
                StatusPill(status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-item copy. Background refresh needs no action, so it has no steps.
String healthItemTitle(AppLocalizations l, String id) => switch (id) {
  'notifications' => l.healthNotifications,
  'exactAlarms' => l.healthExact,
  'fullScreen' => l.healthFullScreen,
  'overlay' => l.healthOverlay,
  'battery' => l.healthBattery,
  'alarms' => l.healthAlarms,
  'focus' => l.healthFocus,
  _ => l.healthBackground,
};

String healthItemState(AppLocalizations l, HealthItem i) {
  final bad = i.needsFix;
  return switch (i.id) {
    'notifications' => bad ? l.healthNotificationsBad : l.healthNotificationsOk,
    'exactAlarms' => bad ? l.healthExactBad : l.healthExactOk,
    'fullScreen' => bad ? l.healthFullScreenBad : l.healthFullScreenOk,
    'overlay' => bad ? l.healthOverlayBad : l.healthOverlayOk,
    'battery' => bad ? l.healthBatteryBad : l.healthBatteryOk,
    'alarms' => bad ? l.healthAlarmsBad : l.healthAlarmsOk,
    'focus' => switch (i.status) {
      HealthStatus.ok => l.healthFocusInfo,
      _ => bad ? l.healthFocusBad : l.healthFocusOk,
    },
    _ => l.healthBackgroundOk,
  };
}

String healthItemBody(AppLocalizations l, String id) => switch (id) {
  'notifications' => l.healthNotificationsBody,
  'exactAlarms' => l.healthExactBody,
  'fullScreen' => l.healthFullScreenBody,
  'overlay' => l.healthOverlayBody,
  'battery' => l.healthBatteryBody,
  'alarms' => l.healthAlarmsBody,
  _ => l.healthFocusBody,
};

List<String> healthItemSteps(AppLocalizations l, String id) => switch (id) {
  'notifications' => [
    l.healthNotificationsStep1,
    l.healthNotificationsStep2,
    l.healthNotificationsStep3,
  ],
  'exactAlarms' => [l.healthExactStep1, l.healthExactStep2, l.healthExactStep3],
  'fullScreen' => [
    l.healthFullScreenStep1,
    l.healthFullScreenStep2,
    l.healthFullScreenStep3,
  ],
  'overlay' => [
    l.healthOverlayStep1,
    l.healthOverlayStep2,
    l.healthOverlayStep3,
  ],
  'battery' => [
    l.healthBatteryStep1,
    l.healthBatteryStep2,
    l.healthBatteryStep3,
    l.healthBatteryStep4,
  ],
  'alarms' => [l.healthAlarmsStep1, l.healthAlarmsStep2, l.healthAlarmsStep3],
  _ => [l.healthFocusStep1, l.healthFocusStep2, l.healthFocusStep3],
};
