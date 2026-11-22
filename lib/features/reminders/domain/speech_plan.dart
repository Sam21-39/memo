enum TitleScript { latin, hi, bn }

/// Devanagari (U+0900-097F) against Bengali (U+0980-09FF): the larger count
/// wins; neither is Latin. The danda marks (U+0964, U+0965) are shared by
/// both scripts and do not count.
TitleScript scriptOf(String text) {
  var hi = 0, bn = 0;
  for (final u in text.runes) {
    if (u == 0x0964 || u == 0x0965) continue;
    if (u >= 0x0900 && u <= 0x097F) {
      hi++;
    } else if (u >= 0x0980 && u <= 0x09FF) {
      bn++;
    }
  }
  if (hi == 0 && bn == 0) return TitleScript.latin;
  return hi >= bn ? TitleScript.hi : TitleScript.bn;
}

/// The voice [title] needs, whatever voices exist: a native-script title is
/// read only by its own language; a Latin one by the chosen playback language
/// (`follow` is English). Bengali or Hindi is never read with an English voice.
String wantedLanguage({required String title, required String playback}) =>
    switch (scriptOf(title)) {
      TitleScript.hi => 'hi',
      TitleScript.bn => 'bn',
      TitleScript.latin => playback == 'follow' ? 'en' : playback,
    };

/// The language to speak [title] in, or null when it must not be spoken.
String? speechLanguage({
  required String title,
  required String playback,
  required Set<String> voices,
}) {
  final wanted = wantedLanguage(title: title, playback: playback);
  return voices.contains(wanted) ? wanted : null;
}
