import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/app_prefs.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/android_alarm_scheduler.dart';
import 'package:memo/features/reminders/data/alarm/ios_alarm_scheduler.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/alarm/local_notification_scheduler.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/spoken_reminder.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'fakes.dart';

class _Plugin implements FlutterLocalNotificationsPlugin {
  NotificationDetails? details;

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
  }) async => details = notificationDetails;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  setUp(() async {
    await setUpDi();
    await sl<AppPrefs>().setInterfaceLocale('hi');
  });

  final r = reminder('r1', 'Fig', DateTime.now().add(const Duration(days: 2)));
  final spoken = SpokenReminder(gender: () => 'female');

  /// Fires a scheduler sent over [channel], decoded from the JSON argument.
  List<Map<String, dynamic>> capture(String channel) {
    final fires = <Map<String, dynamic>>[];
    final c = MethodChannel(channel);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(c, (call) async {
      if (call.method == 'status') return 'authorized';
      final json = (call.arguments as Map)['fires'] as String?;
      if (json != null) {
        fires.addAll((jsonDecode(json) as List).cast<Map<String, dynamic>>());
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(c, null));
    return fires;
  }

  test('android entries carry Hindi labels', () async {
    final fires = capture('memo/alarm');
    await AndroidAlarmScheduler(
      const NativeAlarm(),
      spoken,
      MediaStore(Directory.systemTemp),
    ).schedule(r);
    final e = fires.first;
    expect(e['doneLabel'], 'हो गया');
    expect(e['snoozeLabel'], '10 मिनट बाद फिर बजाएँ');
    expect(e['channelName'], 'अलार्म');
    expect(e['channelDescription'], 'अभी बज रहे रिमाइंडर');
    expect(e['missedChannelName'], 'छूटे');
    expect(e['missedText'], 'छूटा: Fig');
  });

  test('alarmkit entries carry Hindi labels', () async {
    final fires = capture('memo/alarmkit');
    await IosAlarmScheduler(
      const AlarmKit(),
      LocalNotificationScheduler(_Plugin()),
      spoken,
    ).schedule(r);
    expect(fires.first['doneLabel'], 'हो गया');
    expect(fires.first['snoozeLabel'], '10 मिनट बाद फिर बजाएँ');
  });

  test('notification action titles are localised', () async {
    final plugin = _Plugin();
    await LocalNotificationScheduler(plugin).schedule(r);
    final titles = plugin.details!.android!.actions!.map((a) => a.title);
    expect(titles, ['हो गया', '10 मि स्नूज़']);
  });
}
