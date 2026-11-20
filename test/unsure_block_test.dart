import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/core/ui/option_button.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/parser/reminder_parser.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/reminder_confirmation.dart';
import 'package:memo/l10n/app_localizations.dart';
import 'package:memo/l10n/app_localizations_hi.dart';

import 'fakes.dart';

// Never called: the block only reads the cubit on tap.
class _Voice implements VoiceClip {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Stt implements SpeechToText {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets('a day word shows the day on every choice, in Hindi', (
    tester,
  ) async {
    final (repo, scheduler) = await setUpDi();
    final now = DateTime(2026, 11, 20, 14, 30);
    const text = 'कल 8 बजे';
    final unsure = parseReminder(text, now: now).ambiguity!;
    // Same day, two times: the old label would read "8:00 AM" and "8:00 PM".
    expect(unsure.choices.map((c) => c.day).toSet(), hasLength(1));
    final cubit = CaptureCubit(
      SaveReminder(repo, scheduler),
      media: MediaStore(Directory.systemTemp.createTempSync('unsure')),
      voice: _Voice(),
      stt: _Stt(),
      knownTags: () => const [],
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: MemoTheme.light,
        locale: const Locale('hi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: UnsureTimeBlock(
              state: const CaptureState(text: text),
              unsure: unsure,
              now: now,
            ),
          ),
        ),
      ),
    );
    final day = AppLocalizationsHi().dateTomorrow;
    expect(
      find.descendant(
        of: find.byType(OptionButton),
        matching: find.textContaining(day),
      ),
      findsNWidgets(2),
    );
    expect(find.textContaining('8:00 AM'), findsOneWidget);
    expect(find.textContaining('8:00 PM'), findsOneWidget);
  });
}
