import 'package:flutter/services.dart';

import '../domain/entities/reminder.dart';
import '../domain/speech_plan.dart';
import '../../../l10n/l10n.dart';

/// Renders a reminder in the app's own voice, offline, to a sound the alarm
/// plays (`memo/tts`). Rendered at save time because an alarm cannot run
/// text-to-speech while the app is closed. Cached by name: the same words in
/// the same voice are rendered once. The language comes from the speech plan:
/// a title is read only by a voice that can pronounce it, else not at all.
class SpokenReminder {
  SpokenReminder({
    required this.gender,
    this.playback = _follow,
    this.channel = const MethodChannel('memo/tts'),
  });

  static String _follow() => 'follow';

  final MethodChannel channel;

  /// Renders run one at a time: the native side keeps one engine, so two
  /// overlapping renders would talk over each other.
  Future<void> _last = Future.value();

  /// 'female' or 'male', read on every render so a Settings change applies to
  /// the next sync.
  final String Function() gender;

  /// `follow | en | hi | bn`, read on every render for the same reason.
  final String Function() playback;

  Future<Set<String>?>? _voices;
  Set<String>? _good;

  /// Reminders whose last render ran with the voices unknown and failed: their
  /// older renders stay on disk ([prune] skips them) until a lookup works.
  final _unsettled = <String>{};

  /// Languages among en/hi/bn with an offline voice on this phone. Cached;
  /// [refreshVoices] asks again (Settings, app resume). A failed lookup is
  /// never "no voices": it keeps the last good set, or null (unknown).
  Future<Set<String>?> voices() => _voices ??= _loadVoices();

  Future<Set<String>?> refreshVoices() => _voices = _loadVoices();

  Future<Set<String>?> _loadVoices() async {
    try {
      final list = await channel
          .invokeListMethod<String>('voices')
          .timeout(const Duration(seconds: 5));
      return _good = {...?list}.intersection(const {'en', 'hi', 'bn'});
    } catch (_) {
      return _good;
    }
  }

  /// The language [r] would be read in, or null: it does not read aloud, or
  /// no offline voice can pronounce its title. Voices unknown: the wanted
  /// language, and the native side says no if it has no voice.
  Future<String?> languageFor(Reminder r) async {
    if (!r.readAloud) return null;
    final voices = await this.voices();
    return voices == null
        ? wantedLanguage(title: r.title, playback: playback())
        : speechLanguage(title: r.title, playback: playback(), voices: voices);
  }

  /// The sentence read for [r] in [language]: the template of that language,
  /// the note's first line only when the same voice can pronounce it.
  static String textFor(Reminder r, String language) {
    final l = l10n(language);
    final note = r.note?.split('\n').first.trim();
    final readable =
        note != null &&
        note.isNotEmpty &&
        (scriptOf(note) == TitleScript.latin ||
            scriptOf(note) == scriptOf(r.title));
    return readable
        ? l.spokenReminderNote(r.title, note)
        : l.spokenReminder(r.title);
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
  /// — the alarm then rings with the chime (or the voice note) alone.
  Future<String?> soundFor(Reminder r) {
    final run = _last.then((_) => _render(r));
    _last = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<String?> _render(Reminder r) async {
    final known = await voices() != null;
    final lang = await languageFor(r);
    if (lang == null) {
      _unsettled.remove(r.id);
      return null;
    }
    final g = gender();
    final text = textFor(r, lang);
    String? path;
    try {
      path = await channel
          .invokeMethod<String>('render', {
            'text': text, // l10n: native
            'gender': g,
            'language': lang,
            'name': 'say-${r.id}-${_hash('$g|$lang|$text')}',
          })
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
    if (known || path != null) {
      _unsettled.remove(r.id);
    } else {
      _unsettled.add(r.id);
    }
    return path;
  }

  /// Delete [reminderId]'s older renders, keeping the file named [keep]. Call
  /// only after the alarm that uses [keep] was registered: an armed alarm
  /// never points at a deleted file. Does nothing while the voices are
  /// unknown and the render failed: the older renders may still be in use.
  Future<void> prune(String reminderId, String? keep) async {
    if (_unsettled.contains(reminderId)) return;
    try {
      await channel.invokeMethod<void>('prune', {
        'prefix': 'say-$reminderId-',
        'keep': keep,
      });
    } catch (_) {}
  }

  /// Speak a sample in [language] now, for Settings. False when that
  /// language has no offline voice.
  Future<bool> preview(String language) =>
      _speak(l10n(language).spokenPreview, gender(), language);

  /// Speak [r] now: the in-app alarm screen, when nothing native is ringing.
  /// False when nothing was spoken.
  Future<bool> say(Reminder r) async {
    final lang = await languageFor(r);
    return lang != null && await _speak(textFor(r, lang), gender(), lang);
  }

  Future<bool> _speak(String text, String gender, String language) async {
    try {
      return await channel.invokeMethod<bool>('preview', {
            'text': text, // l10n: native
            'gender': gender,
            'language': language,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Android: the system text-to-speech screen, to install a voice.
  Future<void> openTtsSettings() async {
    try {
      await channel.invokeMethod<void>('openTtsSettings');
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
