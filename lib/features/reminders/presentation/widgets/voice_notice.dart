import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/app_prefs.dart';
import '../../../../core/di.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../data/spoken_reminder.dart';
import '../../domain/speech_plan.dart';

/// The honest line under a read-aloud reminder whose title no offline voice
/// can read: how it will ring instead. Nothing when it can be read.
class VoiceNotice extends StatelessWidget {
  const VoiceNotice({
    super.key,
    required this.title,
    required this.readAloud,
    required this.hasVoice,
  });

  final String title;
  final bool readAloud;
  final bool hasVoice;

  @override
  Widget build(BuildContext context) {
    if (!readAloud ||
        title.trim().isEmpty ||
        !sl.isRegistered<SpokenReminder>() ||
        !sl.isRegistered<AppPrefs>()) {
      return const SizedBox.shrink();
    }
    final c = MemoColors.of(context);
    final l = context.l10n;
    final wanted = wantedLanguage(
      title: title,
      playback: sl<AppPrefs>().playbackLocale,
    );
    return FutureBuilder<Set<String>?>(
      future: sl<SpokenReminder>().voices(),
      builder: (context, snap) {
        if (snap.data?.contains(wanted) ?? true) {
          return const SizedBox.shrink();
        }
        final name = languageName(l, wanted);
        return Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MemoSpace.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: c.ink70),
                const SizedBox(width: MemoSpace.space2),
                Expanded(
                  child: Text(
                    hasVoice && Platform.isAndroid
                        ? l.voiceNoticeNote(name)
                        : l.voiceNotice(name),
                    style: MemoType.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: c.ink70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
