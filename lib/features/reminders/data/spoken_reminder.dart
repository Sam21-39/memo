import 'package:flutter/services.dart';

import '../domain/entities/reminder.dart';
import '../../../l10n/l10n.dart';

/// Renders a reminder in the app's own voice, offline, to a sound the alarm
/// plays (`memo/tts`). Rendered at save time because an alarm cannot run
/// text-to-speech while the app is closed. Cached by name: the same words in
/// the same voice are rendered once.
class SpokenReminder {
  SpokenReminder({
    required this.gender,
    this.channel = const MethodChannel('memo/tts'),
  });

  final MethodChannel channel;

  /// Renders run one at a time: the native side keeps one engine, so two
  /// overlapping renders would talk over each other.
  Future<void> _last = Future.value();

  /// 'female' or 'male', read on every render so a Settings change applies to
  /// the next sync.
  final String Function() gender;

  static String textFor(Reminder r) {
    final note = r.note?.split('\n').first.trim();
    // V7: language comes from the speech plan.
    final l = l10n('en');
    return note == null || note.isEmpty
        ? l.spokenReminder(r.title)
        : l.spokenReminderNote(r.title, note);
  }

  /// Stable across runs (unlike String.hashCode): FNV-1a, 32-bit.
  static String _hash(String s) {
    var h = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  /// The rendered sound for [r]: an absolute path on Android, a file name in
  /// Library/Sounds on iOS. Null when it should not speak or rendering failed
  /// — the alarm then rings with the chime alone.
  Future<String?> soundFor(Reminder r) {
    final run = _last.then((_) => _render(r));
    _last = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<String?> _render(Reminder r) async {
    if (!r.readAloud) return null;
    final g = gender();
    final text = textFor(r);
    try {
      return await channel
          .invokeMethod<String>('render', {
            'text': text, // l10n: native
            'gender': g,
            'name': 'say-${r.id}-${_hash('$g|$text')}',
            'prefix': 'say-${r.id}-',
          })
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  /// Speak a sample now, for the Settings preview.
  Future<void> preview(String gender) => _speak(
    l10n('en').spokenPreview, // V7: per-language voices
    gender,
  );

  /// Speak [r] now: the in-app alarm screen, when nothing native is ringing.
  Future<void> say(Reminder r) => _speak(textFor(r), gender());

  Future<void> _speak(String text, String gender) async {
    try {
      await channel.invokeMethod<void>('preview', {
        'text': text, // l10n: native
        'gender': gender,
      });
    } catch (_) {}
  }

  /// Remove a deleted reminder's rendered sounds.
  Future<void> forget(String reminderId) async {
    try {
      await channel.invokeMethod<void>('forget', {
        'prefix': 'say-$reminderId-',
      });
    } catch (_) {}
  }
}
