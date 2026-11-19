import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_version.dart';
import '../../core/chrome/chrome_mode.dart';
import '../../core/di.dart';
import '../../core/feature_flags/feature_flags.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../core/ui/minutes_sheet.dart';
import '../reminders/data/spoken_reminder.dart';
import '../reminders/presentation/widgets/day_section_header.dart';
import '../reminders/presentation/widgets/key_value_row.dart';
import '../reminders/presentation/widgets/section_card.dart';
import 'settings_cubit.dart';
import '../../l10n/strings.dart';

/// Artboard Settings. Rows for features not yet shipped stay hidden behind
/// their flags; Phase 2 is the one greyed forward reference.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final _lifecycle = AppLifecycleListener(
    onResume: () => context.read<SettingsCubit>().refresh(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    final cubit = context.read<SettingsCubit>();
    final glass = ChromeModeScope.of(context) == ChromeMode.glass;
    String allowed(bool? v) =>
        v == null ? '…' : (v ? S.settingsAllowed : S.settingsNotAllowed);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MemoNavBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MemoSpace.gutter,
                    MemoSpace.space6,
                    MemoSpace.gutter,
                    MemoSpace.space8,
                  ),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        S.settingsTitle,
                        style: MemoType.display.copyWith(color: c.ink),
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: S.settingsAlarms),
                    SectionCard(
                      children: [
                        KeyValueRow(
                          label: S.settingsNotifications,
                          onTap: cubit.requestNotifications,
                          child: PillValue(
                            allowed(state.notifications),
                            active: state.notifications == true,
                          ),
                        ),
                        if (state.exactAlarms != null)
                          KeyValueRow(
                            label: S.settingsExactAlarms,
                            onTap: cubit.requestExactAlarms,
                            child: PillValue(
                              allowed(state.exactAlarms),
                              active: state.exactAlarms == true,
                            ),
                          ),
                        if (state.alarmKit != null)
                          KeyValueRow(
                            label: S.settingsFullScreenAlarms,
                            onTap: cubit.requestAlarms,
                            child: PillValue(
                              allowed(state.alarmKit),
                              active: state.alarmKit == true,
                            ),
                          ),
                        if (state.overlay != null)
                          KeyValueRow(
                            label: S.settingsTakeOver,
                            onTap: cubit.openOverlaySettings,
                            child: PillValue(
                              allowed(state.overlay),
                              active: state.overlay == true,
                            ),
                          ),
                        if (state.fullScreen != null)
                          KeyValueRow(
                            label: S.settingsFullScreenAlarm,
                            onTap: cubit.openFullScreenSettings,
                            child: PillValue(
                              allowed(state.fullScreen),
                              active: state.fullScreen == true,
                            ),
                          ),
                        if (flags.nag)
                          KeyValueRow(
                            label: S.settingsDefaultNag,
                            onTap: () async {
                              final m = await showMinutesSheet(
                                context,
                                title: S.settingsDefaultNag,
                                body: S.settingsDefaultNagBody,
                                presets: const [5, 10, 30],
                                current: state.defaultNagMin,
                                label: nagLabel,
                              );
                              if (m != null) {
                                await cubit.setDefaultNag(m == 0 ? null : m);
                              }
                            },
                            child: PillValue(
                              state.defaultNagMin == null
                                  ? S.commonOff
                                  : nagLabel(state.defaultNagMin!),
                            ),
                          ),
                        KeyValueRow(
                          label: S.settingsReadAloud,
                          onTap: cubit.toggleReadAloud,
                          child: PillValue(
                            state.readAloudDefault ? S.commonOn : S.commonOff,
                            active: state.readAloudDefault,
                          ),
                        ),
                        KeyValueRow(
                          label: S.settingsVoice,
                          onTap: () async {
                            final next = state.voiceGender == 'female'
                                ? 'male'
                                : 'female';
                            await cubit.setVoiceGender(next);
                            await sl<SpokenReminder>().preview(next);
                          },
                          child: PillValue(
                            state.voiceGender == 'female'
                                ? S.settingsFemale
                                : S.settingsMale,
                          ),
                        ),
                      ],
                    ),
                    if (state.overlay == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          S.settingsTakeOverHint,
                          style: MemoType.body.copyWith(color: c.ink70),
                        ),
                      ),
                    if (state.notifications == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          S.settingsNotificationsHint,
                          style: MemoType.body.copyWith(color: c.destructive),
                        ),
                      ),
                    if (flags.voiceCapture || flags.imageCapture) ...[
                      const SizedBox(height: MemoSpace.space6),
                      const DaySectionHeader(label: S.settingsCapture),
                      SectionCard(
                        children: [
                          if (flags.voiceCapture)
                            KeyValueRow(
                              label: S.settingsDictation,
                              child: PillValue(
                                state.dictation == false
                                    ? S.settingsDictationNone
                                    : S.settingsEnglish,
                              ),
                            ),
                          if (flags.imageCapture)
                            const KeyValueRow(
                              label: S.settingsReadPhotos,
                              child: PillValue(S.commonOn, active: true),
                            ),
                        ],
                      ),
                    ],
                    if (state.dictation == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          S.settingsNoSpeechModel,
                          style: MemoType.body.copyWith(color: c.ink70),
                        ),
                      ),
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: S.settingsLook),
                    SectionCard(
                      children: [
                        const KeyValueRow(
                          label: S.settingsAppearance,
                          child: PillValue(S.settingsSystem),
                        ),
                        KeyValueRow(
                          label: S.settingsGlass,
                          child: PillValue(
                            glass ? S.settingsFollowsIos : S.settingsSolid,
                            active: glass,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: S.settingsPhase2),
                    const Opacity(
                      opacity: 0.5,
                      child: SectionCard(
                        children: [
                          KeyValueRow(
                            label: S.settingsCloudSync,
                            child: PillValue(S.settingsSoon),
                          ),
                          KeyValueRow(
                            label: S.settingsShared,
                            child: PillValue(S.settingsSoon),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    Text(
                      S.settingsFooter(appVersion),
                      style: MemoType.labelMedium.copyWith(color: c.ink70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
