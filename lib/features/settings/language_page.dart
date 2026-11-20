import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_settings_cubit.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../core/ui/memo_radio_list.dart';
import '../../l10n/l10n.dart';
import '../reminders/presentation/widgets/day_section_header.dart';

/// App language: system default or one of English, Hindi, Bengali.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
