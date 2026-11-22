import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_settings_cubit.dart';
import '../../core/app_version.dart';
import '../../core/di.dart';
import '../../core/feature_flags/feature_flags.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../core/ui/memo_radio_list.dart';
import '../../core/ui/memo_sheet.dart';
import '../../core/ui/memo_toast.dart';
import '../../core/ui/minutes_sheet.dart';
import '../../l10n/l10n.dart';
import '../reminders/presentation/widgets/day_section_header.dart';
import '../reminders/presentation/widgets/key_value_row.dart';
import '../reminders/presentation/widgets/section_card.dart';
import 'permission_status_row.dart';
import 'settings_cubit.dart';

/// Reminders, language and voice, alarm reliability, appearance, about.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final _lifecycle = AppLifecycleListener(
    onResume: () => context.read<SettingsCubit>().refresh(),
  );
  Timer? _toastTimer;
  String? _toast;

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _ringTest(SettingsCubit cubit) async {
    await cubit.ringTest();
    if (!mounted) return;
    final l = context.l10n;
    setState(
      () => _toast = cubit.state.testFailed ? l.testFailed : l.testStarted,
    );
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _pickTheme(AppSettingsCubit app) {
    final l = context.l10n;
    return showMemoSheet<void>(
      context,
      builder: (sheet) => ListView(
        shrinkWrap: true,
        children: [
          SheetHeading(l.settingsTheme),
          BlocBuilder<AppSettingsCubit, AppSettings>(
            bloc: app,
            builder: (_, s) => MemoRadioList<String>(
              value: s.themeMode,
              onChanged: (v) {
                app.setThemeMode(v);
                Navigator.of(sheet).pop();
              },
              options: [
                MemoRadioOption('system', l.settingsSystem),
                MemoRadioOption('light', l.settingsLight),
                MemoRadioOption('dark', l.settingsDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacy() {
    final l = context.l10n;
    final c = MemoColors.of(context);
    return showMemoSheet<void>(
      context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          SheetHeading(l.settingsPrivacy),
          Text(l.privacyBody, style: MemoType.body.copyWith(color: c.ink70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final flags = sl<FeatureFlags>();
    final cubit = context.read<SettingsCubit>();
    final app = context.read<AppSettingsCubit>();
    final appState = context.watch<AppSettingsCubit>().state;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                final toFix = state.toFix;
                final loaded = state.android || state.ios;
                return Column(
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
                              l.settingsTitle,
                              style: MemoType.display.copyWith(color: c.ink),
                            ),
                          ),
                          const SizedBox(height: MemoSpace.space6),
                          DaySectionHeader(label: l.settingsReminders),
                          SectionCard(
                            children: [
                              if (flags.nag)
                                KeyValueRow(
                                  label: l.settingsNoResponse,
                                  onTap: () async {
                                    final m = await showMinutesSheet(
                                      context,
                                      title: l.settingsNoResponse,
                                      body: l.settingsDefaultNagBody,
                                      presets: const [5, 10, 30],
                                      current: state.defaultNagMin,
                                      label: (m) => nagLabel(l, m),
                                    );
                                    if (m != null) {
                                      await cubit.setDefaultNag(
                                        m == 0 ? null : m,
                                      );
                                    }
                                  },
                                  child: Flexible(
                                    child: PillValue(
                                      state.defaultNagMin == null
                                          ? l.commonOff
                                          : nagLabel(l, state.defaultNagMin!),
                                    ),
                                  ),
                                ),
                              KeyValueRow(
                                label: l.settingsReadTitle,
                                onTap: cubit.toggleReadAloud,
                                child: PillValue(
                                  state.readAloudDefault
                                      ? l.commonOn
                                      : l.commonOff,
                                  active: state.readAloudDefault,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: MemoSpace.space6),
                          DaySectionHeader(label: l.settingsLanguageVoice),
                          SectionCard(
                            children: [
                              KeyValueRow(
                                label: l.settingsAppLanguage,
                                onTap: () => context.push('/settings/language'),
                                child: Flexible(
                                  child: PillValue(
                                    appState.interfaceLocale == 'system'
                                        ? l.languageSystem
                                        : endonyms[appState.interfaceLocale]!,
                                  ),
                                ),
                              ),
                              KeyValueRow(
                                label: l.settingsSpeaking,
                                onTap: () => context.push('/settings/language'),
                                child: Flexible(
                                  child: PillValue(
                                    endonyms[appState.inputLocale]!,
                                  ),
                                ),
                              ),
                              KeyValueRow(
                                label: l.settingsReadAloudVoice,
                                onTap: () => context.push('/settings/voice'),
                                child: Flexible(
                                  child: PillValue(
                                    appState.playbackLocale == 'follow'
                                        ? l.voiceFollowShort
                                        : endonyms[appState.playbackLocale]!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: MemoSpace.space6),
                          DaySectionHeader(label: l.settingsReliability),
                          SectionCard(
                            children: [
                              KeyValueRow(
                                label: l.settingsHealth,
                                onTap: () async {
                                  await context.push('/settings/health');
                                  await cubit.refresh();
                                },
                                child: loaded
                                    ? Flexible(child: _HealthPill(toFix))
                                    : const SizedBox.shrink(),
                              ),
                              KeyValueRow(
                                label: l.settingsTest,
                                onTap: () => _ringTest(cubit),
                                child: Flexible(
                                  child: PillValue(l.settingsTestValue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: MemoSpace.space6),
                          DaySectionHeader(label: l.settingsAppearance),
                          SectionCard(
                            children: [
                              KeyValueRow(
                                label: l.settingsTheme,
                                onTap: () => _pickTheme(app),
                                child: PillValue(switch (appState.themeMode) {
                                  'light' => l.settingsLight,
                                  'dark' => l.settingsDark,
                                  _ => l.settingsSystem,
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: MemoSpace.space6),
                          DaySectionHeader(label: l.settingsAbout),
                          SectionCard(
                            children: [
                              KeyValueRow(
                                label: l.settingsPrivacy,
                                onTap: _showPrivacy,
                                child: Flexible(
                                  child: PillValue(l.settingsPrivacyValue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: MemoSpace.space6),
                          Text(
                            l.settingsFooter(appVersion),
                            style: MemoType.labelMedium.copyWith(
                              color: c.ink70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_toast != null)
              Positioned(
                left: MemoSpace.gutter,
                right: MemoSpace.gutter,
                bottom: MemoSpace.space4,
                child: MemoToast(message: _toast!),
              ),
          ],
        ),
      ),
    );
  }
}

/// "All set" or "N things to fix", tinted like the health rows.
class _HealthPill extends StatelessWidget {
  const _HealthPill(this.toFix);

  final int toFix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return toFix == 0
        ? StatusPill(HealthStatus.allowed, text: l.healthAllSet)
        : StatusPill(HealthStatus.fix, text: l.healthToFix(toFix));
  }
}
