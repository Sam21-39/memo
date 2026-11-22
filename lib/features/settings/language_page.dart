import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_settings_cubit.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../core/ui/memo_radio_list.dart';
import '../../l10n/l10n.dart';
import '../reminders/data/speech_to_text.dart';
import '../reminders/presentation/widgets/day_section_header.dart';

/// App language (system default or one of English, Hindi, Bengali) and the
/// language Memō listens in, with what this phone can do offline.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key, this.stt = const SpeechToText()});

  final SpeechToText stt;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
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
                      l.languageTitle,
                      style: MemoType.title.copyWith(color: c.ink),
                    ),
                  ),
                  const SizedBox(height: MemoSpace.space6),
                  DaySectionHeader(label: l.settingsAppLanguage),
                  BlocBuilder<AppSettingsCubit, AppSettings>(
                    builder: (context, s) => MemoRadioList<String>(
                      value: s.interfaceLocale,
                      onChanged: context
                          .read<AppSettingsCubit>()
                          .setInterfaceLocale,
                      options: [
                        MemoRadioOption(
                          'system',
                          l.languageSystem,
                          hint: endonyms[deviceLanguage()],
                        ),
                        const MemoRadioOption('en', 'English'),
                        MemoRadioOption('hi', 'हिन्दी', hint: l.languageHindi),
                        MemoRadioOption('bn', 'বাংলা', hint: l.languageBengali),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoSpace.space6),
                  DaySectionHeader(label: l.settingsSpeaking),
                  _SpeakingList(stt: stt),
                  const SizedBox(height: MemoSpace.space3),
                  Text(
                    l.sttOneLanguage,
                    style: MemoType.body.copyWith(
                      color: c.ink70,
                      fontSize: 13,
                      height: 18 / 13,
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

/// Speaking language: every option stays selectable; the hint says whether
/// this phone can recognise it offline (the failure panel explains the rest).
class _SpeakingList extends StatefulWidget {
  const _SpeakingList({required this.stt});

  final SpeechToText stt;

  @override
  State<_SpeakingList> createState() => _SpeakingListState();
}

class _SpeakingListState extends State<_SpeakingList> {
  final _availability = <String, String>{};

  @override
  void initState() {
    super.initState();
    for (final code in supportedLanguages) {
      widget.stt.availability(sttTag(code)).then((v) {
        if (mounted) setState(() => _availability[code] = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<AppSettingsCubit, AppSettings>(
      builder: (context, s) => MemoRadioList<String>(
        value: s.inputLocale,
        onChanged: context.read<AppSettingsCubit>().setInputLocale,
        options: [
          for (final code in supportedLanguages)
            MemoRadioOption(
              code,
              endonyms[code]!,
              hint: switch (_availability[code]) {
                'installed' => l.sttInstalled,
                'downloadable' => l.sttDownloadable,
                'unavailable' => l.sttUnavailable,
                _ => null,
              },
            ),
        ],
      ),
    );
  }
}
