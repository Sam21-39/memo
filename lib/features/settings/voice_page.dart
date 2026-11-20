import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_settings_cubit.dart';
import '../../core/di.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../core/ui/memo_radio_list.dart';
import '../../core/ui/memo_sheet.dart';
import '../../l10n/l10n.dart';
import '../reminders/data/spoken_reminder.dart';
import '../reminders/presentation/widgets/day_section_header.dart';
import '../reminders/presentation/widgets/key_value_row.dart';
import '../reminders/presentation/widgets/section_card.dart';
import 'settings_cubit.dart';

/// Read-aloud voice: which language reads reminder titles, which voices this
/// phone has offline, a preview, and how to install a missing one. A title
/// is read as written, never translated, and only by a voice that can
/// pronounce it.
class VoicePage extends StatefulWidget {
  const VoicePage({super.key, this.spoken});

  /// Defaults to the registered [SpokenReminder].
  final SpokenReminder? spoken;

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late final SpokenReminder _spoken = widget.spoken ?? sl<SpokenReminder>();
  Set<String>? _voices;
  bool _previewFailed = false;

  @override
  void initState() {
    super.initState();
    _spoken.refreshVoices().then((v) {
      if (mounted) setState(() => _voices = v);
    });
  }

  Future<void> _preview(String playback) async {
    final lang = playback == 'follow' ? interfaceLanguage() : playback;
    final ok = await _spoken.preview(lang);
    if (mounted) setState(() => _previewFailed = !ok);
  }

  Future<void> _howTo() {
    final l = context.l10n;
    final c = MemoColors.of(context);
    return showMemoSheet<void>(
      context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          SheetHeading(l.voiceHowTo),
          Text(
            Platform.isIOS ? l.voiceHowToIos : l.voiceHowToAndroid,
            style: MemoType.body.copyWith(color: c.ink70),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: MemoSpace.space4),
            OutlinedButton(
              onPressed: _spoken.openTtsSettings,
              child: Text(l.voiceOpenSettings),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final app = context.read<AppSettingsCubit>();
    final voices = _voices;
    final small = MemoType.body.copyWith(
      color: c.ink70,
      fontSize: 13,
      height: 18 / 13,
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                      l.voiceTitle,
                      style: MemoType.title.copyWith(color: c.ink),
                    ),
                  ),
                  const SizedBox(height: MemoSpace.space2),
                  Text(
                    l.voiceBody,
                    style: MemoType.body.copyWith(color: c.ink70),
                  ),
                  const SizedBox(height: MemoSpace.space6),
                  BlocBuilder<AppSettingsCubit, AppSettings>(
                    builder: (context, s) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MemoRadioList<String>(
                          value: s.playbackLocale,
                          onChanged: (v) {
                            setState(() => _previewFailed = false);
                            app.setPlaybackLocale(v);
                          },
                          options: [
                            MemoRadioOption(
                              'follow',
                              l.voiceFollow,
                              hint: l.voiceFollowHint,
                            ),
                            for (final code in supportedLanguages)
                              MemoRadioOption(
                                code,
                                endonyms[code]!,
                                hint: voices != null && !voices.contains(code)
                                    ? l.voiceMissing(languageName(l, code))
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: MemoSpace.space4),
                        OutlinedButton.icon(
                          onPressed: () => _preview(s.playbackLocale),
                          icon: const Icon(Icons.volume_up_outlined),
                          label: Text(l.voicePreview),
                        ),
                        if (_previewFailed) ...[
                          const SizedBox(height: MemoSpace.space2),
                          Semantics(
                            liveRegion: true,
                            child: Text(l.voicePreviewFailed, style: small),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (voices != null && voices.length < 3) ...[
                    const SizedBox(height: MemoSpace.space6),
                    SectionCard(
                      children: [
                        for (final code in supportedLanguages)
                          if (!voices.contains(code))
                            KeyValueRow(
                              label: languageName(l, code),
                              child: PillValue(l.voiceNotInstalled),
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: MemoSpace.space6),
                  DaySectionHeader(label: l.settingsVoice),
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) => SectionCard(
                      children: [
                        KeyValueRow(
                          label: l.settingsVoice,
                          onTap: () async {
                            final next = state.voiceGender == 'female'
                                ? 'male'
                                : 'female';
                            final app = context.read<AppSettingsCubit>();
                            await context.read<SettingsCubit>().setVoiceGender(
                              next,
                            );
                            await _spoken.preview('en');
                            // Renders are named by voice: re-render lazily.
                            await app.onLanguageChanged?.call();
                          },
                          child: PillValue(
                            state.voiceGender == 'female'
                                ? l.settingsFemale
                                : l.settingsMale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoSpace.space2),
                  Text(l.voiceGenderHint, style: small),
                  const SizedBox(height: MemoSpace.space4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: _howTo,
                      child: Text(l.voiceHowTo),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
