import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/edit/edit_cubit.dart';

import 'fakes.dart';

void main() {
  late InMemoryRepository repo;
  late FakeScheduler scheduler;
  late MediaStore media;

  setUp(() {
    repo = InMemoryRepository();
    scheduler = FakeScheduler();
    media = MediaStore(Directory.systemTemp.createTempSync('edit'));
    File(media.draftVoicePath).writeAsBytesSync([0]);
  });

  EditCubit build({bool draftClip = true}) => EditCubit(
    SaveReminder(repo, scheduler),
    draft: reminder('d', 'Bins', DateTime(2026, 11, 4, 19)),
    draftClip: draftClip,
    media: media,
  );

  test('prefills from the draft and keeps its clip', () {
    final cubit = build();
    expect(cubit.state.title, 'Bins');
    expect(cubit.state.hasClip, isTrue);
    expect(cubit.state.draftClip, isTrue);
  });

  test('closing without saving keeps an inherited draft clip', () async {
    await build().close();
    expect(File(media.draftVoicePath).existsSync(), isTrue);
  });

  test('a new one-off in the past cannot be saved and says why', () {
    final cubit = EditCubit(SaveReminder(repo, scheduler))
      ..setTitle('Bins')
      ..setDueAt(DateTime.now().subtract(const Duration(hours: 1)));
    expect(cubit.state.pastBlocked(DateTime.now()), isTrue);
    expect(cubit.state.canSave, isFalse);
  });

  test('a failed save keeps the clip the reminder already had', () async {
    final old = reminder('e', 'Bins', DateTime(2026, 11, 4, 19));
    repo = InMemoryRepository([old.copyWith(hasVoice: true)]);
    File(media.voicePath('e')).writeAsBytesSync([1, 2, 3]);
    File(media.draftVoicePath).writeAsBytesSync([9]);
    final cubit = EditCubit(
      SaveReminder(repo, scheduler),
      existing: old.copyWith(hasVoice: true),
      draftClip: true,
      media: media,
    );
    repo.failSave = true;
    await cubit.save();
    expect(File(media.voicePath('e')).readAsBytesSync(), [1, 2, 3]);
    expect(File(media.draftVoicePath).readAsBytesSync(), [9]);
  });

  test('removing a clip keeps the file when the save fails', () async {
    final old = reminder('e', 'Bins', DateTime(2026, 11, 4, 19));
    repo = InMemoryRepository([old.copyWith(hasVoice: true)]);
    File(media.voicePath('e')).writeAsBytesSync([1, 2, 3]);
    final cubit = EditCubit(
      SaveReminder(repo, scheduler),
      existing: old.copyWith(hasVoice: true),
      media: media,
    );
    await cubit.deleteClip();
    repo.failSave = true;
    await cubit.save();
    expect(File(media.voicePath('e')).existsSync(), isTrue);
    repo.failSave = false;
    await cubit.save();
    expect(File(media.voicePath('e')).existsSync(), isFalse);
    expect(repo.all.single.hasVoice, isFalse);
  });

  test('a commit that fails after the first rename rolls back', () async {
    final failing = MediaStore(
      File(media.draftVoicePath).parent,
      installSound: (_, _) async => throw StateError('install'),
    );
    File(failing.voicePath('e')).writeAsBytesSync([1, 2, 3]);
    File(failing.draftVoicePath).writeAsBytesSync([9]);
    await expectLater(failing.commitVoice('e'), throwsStateError);
    expect(File(failing.voicePath('e')).readAsBytesSync(), [1, 2, 3]);
    expect(File(failing.draftVoicePath).readAsBytesSync(), [9]);
  });

  test(
    'deleteVoice drops the backup; recoverBackups restores a lost clip',
    () async {
      final bak = File(media.voicePath('e').replaceFirst('.wav', '.bak.wav'))
        ..writeAsBytesSync([7]);
      await media.recoverBackups();
      expect(File(media.voicePath('e')).readAsBytesSync(), [7]);
      expect(bak.existsSync(), isFalse);

      bak.writeAsBytesSync([8]);
      await media.deleteVoice('e');
      expect(bak.existsSync(), isFalse);
      expect(File(media.voicePath('e')).existsSync(), isFalse);
    },
  );
}
