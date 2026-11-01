import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/app_version.dart';

void main() {
  test('Settings shows the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });
}
