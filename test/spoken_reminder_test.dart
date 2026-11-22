import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/alarm/android_alarm_scheduler.dart';
import 'package:memo/features/reminders/data/alarm/ios_alarm_scheduler.dart';
import 'package:memo/features/reminders/data/alarm/local_notification_scheduler.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/spoken_reminder.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';

import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'fakes.dart';

const _tts = MethodChannel('memo/tts');
const _alarm = MethodChannel('memo/alarm');
final _messenger =
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// What the phone's TTS answers, and every call it got, in order.
var _voices = <String>['en', 'hi', 'bn'];
var _voicesFail = false;
var _renderFail = false;
final _log = <String>[];
final _args = <String, Map>{};

void _mock({Duration renderTime = Duration.zero}) {
  _voices = ['en', 'hi', 'bn'];
  _voicesFail = false;
  _renderFail = false;
  _log.clear();
  _args.clear();
  _messenger.setMockMethodCallHandler(_tts, (call) async {
    _log.add('tts.${call.method}');
    _args[call.method] = call.arguments as Map? ?? {};
    switch (call.method) {
      case 'voices':
        if (_voicesFail) throw PlatformException(code: 'init');
        return _voices;
      case 'render':
        await Future<void>.delayed(renderTime);
        if (_renderFail) return null;
        return '/sounds/${(call.arguments as Map)['name']}.wav';
      case 'preview':
        return _voices.contains((call.arguments as Map)['language']);
      default:
        return null;
    }
  });
  _messenger.setMockMethodCallHandler(_alarm, (call) async {
    _log.add('alarm.${call.method}');
    return null;
  });
  addTearDown(() {
    _messenger.setMockMethodCallHandler(_tts, null);
    _messenger.setMockMethodCallHandler(_alarm, null);
  });
}

Reminder _r(String title, {String? note, bool voice = false}) => reminder(
  'a',
  title,
  DateTime.now().add(const Duration(days: 1)),
  note: note,
).copyWith(readAloud: true, hasVoice: voice);

List<Map> jsonFires(MethodCall c) =>
    (jsonDecode((c.arguments as Map)['fires'] as String) as List).cast<Map>();

/// Notifications plugin that only records that something was registered.
class FakePlugin implements FlutterLocalNotificationsPlugin {
  FakePlugin(this.order);
  final List<String> order;

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async => order.add('zoned');

  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

int _renders() => _log.where((e) => e == 'tts.render').length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));

  test('concurrent renders never overlap on the channel', () async {
    var active = 0;
    var maxActive = 0;
    _mock();
    _messenger.setMockMethodCallHandler(_tts, (call) async {
      if (call.method == 'voices') return ['en'];
      active++;
      maxActive = max(maxActive, active);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      active--;
      return 'say.wav';
    });
    final tts = SpokenReminder(gender: () => 'female');
    final r = _r('Bins');
    final sounds = await Future.wait([
      tts.soundFor(r),
      tts.soundFor(r),
      tts.soundFor(r),
    ]);
    expect(sounds, everyElement('say.wav'));
    expect(maxActive, 1);
  });

  test(
    'a Bengali title with only an English voice is never rendered',
    () async {
      _mock();
      _voices = ['en'];
      final tts = SpokenReminder(gender: () => 'female', playback: () => 'en');
      expect(await tts.soundFor(_r('ওষুধ খান')), isNull);
      expect(await tts.languageFor(_r('ওষুধ খান')), isNull);
      expect(_renders(), 0);
      // Latin titles still speak.
      expect(await tts.soundFor(_r('Pills')), isNotNull);
      expect(_renders(), 1);
    },
  );

  test('read aloud off renders nothing', () async {
    _mock();
    final tts = SpokenReminder(gender: () => 'female');
    expect(await tts.soundFor(_r('Pills').copyWith(readAloud: false)), isNull);
    expect(_renders(), 0);
  });

  test('the render name changes with playback language and gender', () async {
    _mock();
    var playback = 'follow';
    var gender = 'female';
    final tts = SpokenReminder(gender: () => gender, playback: () => playback);
    final r = _r('Pills');
    final follow = await tts.soundFor(r);
    expect(_args['render']!['language'], 'en');
    final again = await tts.soundFor(r);
    expect(again, follow, reason: 'same words and voice: same file');
    playback = 'hi';
    final hindi = await tts.soundFor(r);
    expect(_args['render']!['language'], 'hi');
    expect(hindi, isNot(follow));
    gender = 'male';
    expect(await tts.soundFor(r), isNot(hindi));
  });

  test(
    'the spoken template is the voice language, the note only if readable',
    () async {
      _mock();
      final tts = SpokenReminder(gender: () => 'female');
      await tts.soundFor(_r('दवा लो', note: 'दो गोली'));
      expect(_args['render']!['language'], 'hi');
      expect(_args['render']!['text'], 'रिमाइंडर। दवा लो। दो गोली।');
      // A Bengali note under a Hindi title is not spoken by the Hindi voice.
      await tts.soundFor(_r('दवा लो', note: 'ওষুধ'));
      expect(_args['render']!['text'], 'रिमाइंडर। दवा लो।');
      await tts.soundFor(_r('Pills', note: 'Two with water\nsecond line'));
      expect(_args['render']!['text'], 'Reminder. Pills. Two with water.');
    },
  );

  test('voices are cached until refreshed', () async {
    _mock();
    final tts = SpokenReminder(gender: () => 'female');
    expect(await tts.voices(), {'en', 'hi', 'bn'});
    _voices = ['en'];
    expect(await tts.voices(), {'en', 'hi', 'bn'});
    expect(await tts.refreshVoices(), {'en'});
    expect(await tts.voices(), {'en'});
    // Anything but en/hi/bn is ignored.
    _voices = ['en', 'fr'];
    expect(await tts.refreshVoices(), {'en'});
    // A broken channel is not "no voices": the last good set stays.
    _voicesFail = true;
    expect(await tts.refreshVoices(), {'en'});
    expect(await SpokenReminder(gender: () => 'female').voices(), isNull);
  });

  group('a failed voice lookup is unknown, not "no voices"', () {
    test('the last good set stays and its renders are still pruned', () async {
      _mock();
      final tts = SpokenReminder(gender: () => 'female');
      expect(await tts.soundFor(_r('Pills')), isNotNull);
      _voicesFail = true;
      await tts.refreshVoices();
      expect(await tts.soundFor(_r('ওষুধ')), isNotNull, reason: 'hi stays');
      await tts.prune('a', 'x.wav');
      expect(_log.last, 'tts.prune');
    });

    test(
      'no good set yet: renders kept, never pruned, then it recovers',
      () async {
        _mock();
        _voicesFail = true;
        _renderFail = true;
        final tts = SpokenReminder(gender: () => 'female');
        expect(await tts.voices(), isNull);
        expect(await tts.soundFor(_r('Pills')), isNull);
        expect(
          _renders(),
          1,
          reason: 'unknown: still tries the wanted language',
        );
        await tts.prune('a', null);
        expect(_log, isNot(contains('tts.prune')));
        // Voices answer again.
        _voicesFail = false;
        _renderFail = false;
        expect(await tts.refreshVoices(), {'en', 'hi', 'bn'});
        expect(await tts.soundFor(_r('Pills')), isNotNull);
        await tts.prune('a', 'x.wav');
        expect(_log.last, 'tts.prune');
      },
    );

    test('unknown, but a render still works: that file is used', () async {
      _mock();
      _voicesFail = true;
      final tts = SpokenReminder(gender: () => 'female');
      expect(await tts.soundFor(_r('Pills')), isNotNull);
      await tts.prune('a', 'x.wav');
      expect(_log.last, 'tts.prune');
    });
  });

  test('preview and say report whether anything was spoken', () async {
    _mock();
    _voices = ['en'];
    final tts = SpokenReminder(gender: () => 'female');
    expect(await tts.preview('en'), isTrue);
    expect(await tts.preview('bn'), isFalse);
    expect(_args['preview']!['language'], 'bn');
    expect(_args['preview']!['text'], 'রিমাইন্ডার। ওষুধ খান।');
    _log.clear();
    expect(await tts.say(_r('ওষুধ')), isFalse, reason: 'no bn voice');
    expect(_log, ['tts.voices'], reason: 'nothing sent to speak');
    expect(await tts.say(_r('Pills')), isTrue);
  });

  group('prune runs after the alarm was registered', () {
    late Directory dir;
    late AndroidAlarmScheduler scheduler;

    setUp(() {
      _mock();
      dir = Directory.systemTemp.createTempSync('prune');
      addTearDown(() => dir.deleteSync(recursive: true));
      scheduler = AndroidAlarmScheduler(
        const NativeAlarm(),
        SpokenReminder(gender: () => 'female'),
        MediaStore(dir),
      );
    });

    test(
      'schedule: render, native schedule, then prune keeping the file',
      () async {
        await scheduler.schedule(_r('Pills'));
        expect(_log, [
          'tts.voices',
          'tts.render',
          'alarm.schedule',
          'tts.prune',
        ]);
        expect(_args['prune']!['prefix'], 'say-a-');
        expect(_args['prune']!['keep'], '${_args['render']!['name']}.wav');
      },
    );

    test('syncAll: every render, one replaceAll, then every prune', () async {
      final b = reminder(
        'b',
        'Bins',
        DateTime.now().add(const Duration(days: 1)),
      ).copyWith(readAloud: true);
      await scheduler.syncAll([_r('Pills'), b]);
      expect(_log, [
        'tts.voices',
        'tts.render',
        'tts.render',
        'alarm.replaceAll',
        'tts.prune',
        'tts.prune',
      ]);
    });

    test('two overlapping syncAll calls run one after the other', () async {
      _mock(renderTime: const Duration(milliseconds: 20));
      scheduler = AndroidAlarmScheduler(
        const NativeAlarm(),
        SpokenReminder(gender: () => 'female'),
        MediaStore(dir),
      );
      await Future.wait([
        scheduler.syncAll([_r('Pills')]),
        scheduler.syncAll([_r('Pills')]),
      ]);
      expect(_log, [
        'tts.voices',
        'tts.render',
        'alarm.replaceAll',
        'tts.prune',
        'tts.render',
        'alarm.replaceAll',
        'tts.prune',
      ]);
    });

    test(
      'no voice: the voice note rings after the chime, old renders go',
      () async {
        _voices = [];
        String? speech;
        _messenger.setMockMethodCallHandler(_alarm, (call) async {
          _log.add('alarm.${call.method}');
          speech = (jsonFires(call).single)['speech'] as String?;
          return null;
        });
        await scheduler.schedule(_r('ওষুধ', voice: true));
        expect(speech, '${dir.path}/a.wav');
        expect(_log, ['tts.voices', 'alarm.schedule', 'tts.prune']);
        expect(_args['prune']!['keep'], isNull);
        // Without the voice note: chime only.
        await scheduler.schedule(_r('ওষুধ'));
        expect(speech, isNull);
      },
    );
  });

  group('iOS AlarmKit prunes after the native call', () {
    const kit = MethodChannel('memo/alarmkit');
    late IosAlarmScheduler scheduler;
    late List<Map> sent;

    setUp(() {
      _mock();
      sent = [];
      _messenger.setMockMethodCallHandler(kit, (call) async {
        if (call.method == 'status') return 'authorized';
        _log.add('kit.${call.method}');
        if (call.method == 'replaceAll' || call.method == 'schedule') {
          sent = jsonFires(call);
        }
        return null;
      });
      addTearDown(() => _messenger.setMockMethodCallHandler(kit, null));
      scheduler = IosAlarmScheduler(
        const AlarmKit(),
        LocalNotificationScheduler(FakePlugin([]), capPending: false),
        SpokenReminder(gender: () => 'female'),
      );
    });

    test('schedule: render, AlarmKit, then prune', () async {
      await scheduler.schedule(_r('Pills'));
      expect(_log, ['tts.voices', 'tts.render', 'kit.schedule', 'tts.prune']);
      expect(
        _args['prune']!['keep'],
        '/sounds/${_args['render']!['name']}.wav',
      );
    });

    test(
      'syncAll: 64 soonest fires, every render, one call, every prune',
      () async {
        final many = [
          for (var i = 0; i < 70; i++)
            reminder(
              'r$i',
              'Pills',
              DateTime.now().add(Duration(days: 1, minutes: i)),
            ).copyWith(readAloud: true),
        ];
        await scheduler.syncAll(many);
        expect(sent, hasLength(64));
        final renders = _log.where((e) => e == 'tts.render').length;
        expect(renders, 64);
        expect(_log.where((e) => e == 'kit.replaceAll'), hasLength(1));
        final at = _log.indexOf('kit.replaceAll');
        expect(_log.sublist(0, at).where((e) => e == 'tts.prune'), isEmpty);
        expect(_log.sublist(at + 1), everyElement('tts.prune'));
        expect(_log.length - at - 1, 64);
      },
    );
  });

  test(
    'notification path prunes after every notification was registered',
    () async {
      _mock();
      final order = <String>[];
      final tts = SpokenReminder(gender: () => 'female');
      final scheduler = LocalNotificationScheduler(
        FakePlugin(order),
        soundFor: (r) async {
          order.add('sound');
          return tts.soundFor(r);
        },
        onScheduled: (r, sound) async => order.add('prune:${r.id}'),
        capPending: false,
        burst: false,
      );
      await scheduler.syncAll([_r('Pills')]);
      expect(order, ['sound', 'zoned', 'prune:a']);
    },
  );
}
