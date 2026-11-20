import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_version.dart';
import '../../core/app_settings_cubit.dart';
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
import '../../l10n/l10n.dart';

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
    final appLocale = context.watch<AppSettingsCubit>().state.interfaceLocale;
    final glass = ChromeModeScope.of(context) == ChromeMode.glass;
    String allowed(bool? v) => v == null
        ? '…'
        : (v ? context.l10n.settingsAllowed : context.l10n.settingsNotAllowed);

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
                        context.l10n.settingsTitle,
                        style: MemoType.display.copyWith(color: c.ink),
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    DaySectionHeader(label: context.l10n.settingsLanguageVoice),
                    SectionCard(
                      children: [
                        KeyValueRow(
                          label: context.l10n.settingsAppLanguage,
                          onTap: () => context.push('/settings/language'),
                          child: PillValue(
                            appLocale == 'system'
                                ? context.l10n.languageSystem
                                : endonyms[appLocale]!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    DaySectionHeader(label: context.l10n.settingsAlarms),
                    SectionCard(
                      children: [
                        KeyValueRow(
                          label: context.l10n.settingsNotifications,
                          onTap: cubit.requestNotifications,
                          child: PillValue(
                            allowed(state.notifications),
                            active: state.notifications == true,
                          ),
                        ),
                        if (state.exactAlarms != null)
                          KeyValueRow(
                            label: context.l10n.settingsExactAlarms,
                            onTap: cubit.requestExactAlarms,
                            child: PillValue(
                              allowed(state.exactAlarms),
                              active: state.exactAlarms == true,
                            ),
                          ),
                        if (state.alarmKit != null)
                          KeyValueRow(
                            label: context.l10n.settingsFullScreenAlarms,
                            onTap: cubit.requestAlarms,
                            child: PillValue(
                              allowed(state.alarmKit),
                              active: state.alarmKit == true,
                            ),
                          ),
                        if (state.overlay != null)
                          KeyValueRow(
                            label: context.l10n.settingsTakeOver,
                            onTap: cubit.openOverlaySettings,
                            child: PillValue(
                              allowed(state.overlay),
                              active: state.overlay == true,
                            ),
                          ),
                        if (state.fullScreen != null)
                          KeyValueRow(
                            label: context.l10n.settingsFullScreenAlarm,
                            onTap: cubit.openFullScreenSettings,
                            child: PillValue(
                              allowed(state.fullScreen),
                              active: state.fullScreen == true,
                            ),
                          ),
                        if (flags.nag)
                          KeyValueRow(
                            label: context.l10n.settingsDefaultNag,
                            onTap: () async {
                              final m = await showMinutesSheet(
                                context,
                                title: context.l10n.settingsDefaultNag,
                                body: context.l10n.settingsDefaultNagBody,
                                presets: const [5, 10, 30],
                                current: state.defaultNagMin,
                                label: (m) => nagLabel(context.l10n, m),
                              );
                              if (m != null) {
                                await cubit.setDefaultNag(m == 0 ? null : m);
                              }
                            },
                            child: PillValue(
                              state.defaultNagMin == null
                                  ? context.l10n.commonOff
                                  : nagLabel(
                                      context.l10n,
                                      state.defaultNagMin!,
                                    ),
                            ),
                          ),
                        KeyValueRow(
                          label: context.l10n.settingsReadAloud,
                          onTap: cubit.toggleReadAloud,
                          child: PillValue(
                            state.readAloudDefault
                                ? context.l10n.commonOn
                                : context.l10n.commonOff,
                            active: state.readAloudDefault,
                          ),
                        ),
                        KeyValueRow(
                          label: context.l10n.settingsVoice,
                          onTap: () async {
                            final next = state.voiceGender == 'female'
                                ? 'male'
                                : 'female';
                            await cubit.setVoiceGender(next);
                            await sl<SpokenReminder>().preview(next);
                          },
                          child: PillValue(
                            state.voiceGender == 'female'
                                ? context.l10n.settingsFemale
                                : context.l10n.settingsMale,
                          ),
                        ),
                      ],
                    ),
                    if (state.overlay == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          context.l10n.settingsTakeOverHint,
                          style: MemoType.body.copyWith(color: c.ink70),
                        ),
                      ),
                    if (state.notifications == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          context.l10n.settingsNotificationsHint,
                          style: MemoType.body.copyWith(color: c.destructive),
                        ),
                      ),
                    if (flags.voiceCapture || flags.imageCapture) ...[
                      const SizedBox(height: MemoSpace.space6),
                      DaySectionHeader(label: context.l10n.settingsCapture),
                      SectionCard(
                        children: [
                          if (flags.voiceCapture)
                            KeyValueRow(
                              label: context.l10n.settingsDictation,
                              child: PillValue(
                                state.dictation == false
                                    ? context.l10n.settingsDictationNone
                                    : context.l10n.settingsEnglish,
                              ),
                            ),
                          if (flags.imageCapture)
                            KeyValueRow(
                              label: context.l10n.settingsReadPhotos,
                              child: PillValue(
                                context.l10n.commonOn,
                                active: true,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (state.dictation == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          context.l10n.settingsNoSpeechModel,
                          style: MemoType.body.copyWith(color: c.ink70),
                        ),
                      ),
                    const SizedBox(height: MemoSpace.space6),
                    DaySectionHeader(label: context.l10n.settingsLook),
                    SectionCard(
                      children: [
                        KeyValueRow(
                          label: context.l10n.settingsAppearance,
                          child: PillValue(context.l10n.settingsSystem),
                        ),
                        KeyValueRow(
                          label: context.l10n.settingsGlass,
                          child: PillValue(
                            glass
                                ? context.l10n.settingsFollowsIos
                                : context.l10n.settingsSolid,
                            active: glass,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    DaySectionHeader(label: context.l10n.settingsPhase2),
                    Opacity(
                      opacity: 0.5,
                      child: SectionCard(
                        children: [
                          KeyValueRow(
                            label: context.l10n.settingsCloudSync,
                            child: PillValue(context.l10n.settingsSoon),
                          ),
                          KeyValueRow(
                            label: context.l10n.settingsShared,
                            child: PillValue(context.l10n.settingsSoon),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    Text(
                      context.l10n.settingsFooter(appVersion),
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
