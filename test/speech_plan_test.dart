import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/speech_plan.dart';

void main() {
  group('scriptOf', () {
    test('Devanagari, Bengali, else Latin', () {
      expect(scriptOf('दवा लेनी है'), TitleScript.hi);
      expect(scriptOf('ওষুধ খান'), TitleScript.bn);
      expect(scriptOf('Take pills'), TitleScript.latin);
      expect(scriptOf('12:30 !'), TitleScript.latin);
      expect(scriptOf(''), TitleScript.latin);
    });

    test('a mixed title takes the majority script', () {
      expect(scriptOf('Call माँ आज शाम'), TitleScript.hi);
      expect(scriptOf('Doctor ডাক্তার দেখানো'), TitleScript.bn);
      expect(scriptOf('मा ওষুধ খান'), TitleScript.bn);
    });

    test('the shared danda marks do not tip the count', () {
      expect(scriptOf('ক।'), TitleScript.bn);
      expect(scriptOf('क।'), TitleScript.hi);
      expect(scriptOf('ক॥ ।।'), TitleScript.bn);
      expect(scriptOf('।'), TitleScript.latin);
    });
  });

  group('speechLanguage', () {
    test('a Bengali title is never read with an English voice', () {
      expect(
        speechLanguage(title: 'ওষুধ খান', playback: 'en', voices: {'en'}),
        isNull,
      );
      expect(
        speechLanguage(
          title: 'ওষুধ খান',
          playback: 'follow',
          voices: {'en', 'hi'},
        ),
        isNull,
      );
      expect(
        speechLanguage(title: 'ওষুধ খান', playback: 'en', voices: {'en', 'bn'}),
        'bn',
      );
    });

    test('a Hindi title follows its own language whatever the pref says', () {
      expect(
        speechLanguage(title: 'दवा लो', playback: 'bn', voices: {'bn', 'hi'}),
        'hi',
      );
      expect(
        speechLanguage(title: 'दवा लो', playback: 'follow', voices: {'en'}),
        isNull,
      );
    });

    test('a Latin title uses the chosen language; follow is English', () {
      expect(
        speechLanguage(title: 'Pills', playback: 'hi', voices: {'en', 'hi'}),
        'hi',
      );
      expect(
        speechLanguage(
          title: 'Pills',
          playback: 'follow',
          voices: {'en', 'hi'},
        ),
        'en',
      );
      expect(
        speechLanguage(title: 'Pills', playback: 'hi', voices: {'en'}),
        isNull,
      );
      expect(
        speechLanguage(title: 'Pills', playback: 'follow', voices: {}),
        isNull,
      );
    });

    test('wantedLanguage ignores the voices', () {
      expect(wantedLanguage(title: 'ওষুধ', playback: 'en'), 'bn');
      expect(wantedLanguage(title: 'Pills', playback: 'follow'), 'en');
      expect(wantedLanguage(title: 'Pills', playback: 'bn'), 'bn');
    });
  });
}
