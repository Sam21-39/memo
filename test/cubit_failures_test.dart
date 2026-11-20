import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/l10n/l10n.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/archive/archive_cubit.dart';
import 'package:memo/features/reminders/presentation/detail/detail_cubit.dart';
import 'package:memo/features/reminders/presentation/edit/edit_cubit.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_state.dart';

import 'fakes.dart';

void main() {
  late InMemoryRepository repo;
  late FakeScheduler scheduler;
  late SaveReminder save;
  late DeleteReminder delete;
  final when = DateTime(2026, 11, 20, 9);

  setUp(() {
    repo = InMemoryRepository();
    scheduler = FakeScheduler();
    save = SaveReminder(repo, scheduler);
    delete = DeleteReminder(repo, scheduler, (_) async {});
  });

  test('capture save failure returns to typing with an error', () async {
    final media = MediaStore(Directory.systemTemp.createTempSync('fail'));
    final cubit = CaptureCubit(
      save,
      media: media,
      voice: null,
      stt: null,
      knownTags: () => const [],
      clock: () => when,
    )..setText('Bins at 7pm');
    repo.failSave = true;
    await cubit.save();
    expect(cubit.state.phase, CapturePhase.typing);
    expect(cubit.state.error, "Couldn't save. Nothing changed, try again.");
  });

  test('edit save failure leaves the form editable with an error', () async {
    final cubit = EditCubit(save)..setTitle('Bins');
    repo.failSave = true;
    await cubit.save();
    expect(cubit.state.status, EditStatus.editing);
    expect(cubit.state.error, l10n().saveFailed);
  });

  test('archive reopen failure is reported', () async {
    final done = reminder('1', 'Bins', when, doneAt: when);
    repo = InMemoryRepository([done]);
    save = SaveReminder(repo, scheduler);
    final cubit = ArchiveCubit(repo, save);
    await cubit.load();
    repo.failSave = true;
    await cubit.reopen(done);
    expect(cubit.state.error, l10n().saveFailed);
    cubit.clearError();
    expect(cubit.state.error, isNull);
  });

  test('home write failure is reported on the ready state', () async {
    repo = InMemoryRepository([reminder('1', 'Bins', when)]);
    save = SaveReminder(repo, scheduler);
    final cubit = HomeCubit(repo, save, delete);
    await cubit.load();
    repo.failSave = true;
    await cubit.complete(repo.all.single);
    final state = cubit.state as HomeReady;
    expect(state.error, l10n().saveFailed);
    await cubit.close();
  });

  test(
    'detail write failure is reported, delete failure keeps the row',
    () async {
      repo = InMemoryRepository([reminder('1', 'Bins', when)]);
      save = SaveReminder(repo, scheduler);
      delete = DeleteReminder(repo, scheduler, (_) async {});
      final cubit = DetailCubit('1', repo, save, delete);
      await cubit.load();

      repo.failSave = true;
      await cubit.complete();
      expect((cubit.state as DetailReady).error, l10n().saveFailed);
      repo.failSave = false;

      repo.failDelete = true;
      expect(await cubit.delete(), isFalse);
      expect((cubit.state as DetailReady).error, l10n().deleteFailed);
      expect(repo.all, isNotEmpty);
      await cubit.close();
    },
  );

  testWidgets('a second swipe-delete never deletes a row twice', (
    tester,
  ) async {
    final gated = _GatedRepository([
      reminder('a', 'A', when),
      reminder('b', 'B', when),
    ]);
    final cubit = HomeCubit(
      gated,
      SaveReminder(gated, scheduler),
      DeleteReminder(gated, scheduler, (_) async {}),
    );
    await cubit.load();
    await cubit.delete(gated.all.firstWhere((r) => r.id == 'a'));
    gated.gate = Completer<void>();
    // The Undo window ends: A's delete starts and stalls on the gate.
    await tester.pump(HomeCubit.undoWindow);
    // Swiping B meanwhile must not re-run A's delete.
    await cubit.delete(gated.all.firstWhere((r) => r.id == 'b'));
    gated.gate!.complete();
    await tester.pump();
    await tester.pump(HomeCubit.undoWindow);
    await tester.pump();
    expect(gated.deleted, ['a', 'b']);
    await cubit.close();
  });
  testWidgets('Undo during an in-flight delete is a no-op; close skips it', (
    tester,
  ) async {
    final gated = _GatedRepository([reminder('a', 'A', when)]);
    final cubit = HomeCubit(
      gated,
      SaveReminder(gated, scheduler),
      DeleteReminder(gated, scheduler, (_) async {}),
    );
    await cubit.load();
    await cubit.delete(gated.all.single);
    gated.gate = Completer<void>();
    await tester.pump(HomeCubit.undoWindow);
    cubit.undoDelete();
    expect((cubit.state as HomeReady).pendingDelete, isNotNull);
    final closing = cubit.close();
    gated.gate!.complete();
    await closing;
    expect(gated.deleted, ['a']);
  });

  test(
    'a pending delete commits when the app goes to the background',
    () async {
      repo = InMemoryRepository([reminder('a', 'A', when)]);
      final cubit = HomeCubit(
        repo,
        SaveReminder(repo, scheduler),
        DeleteReminder(repo, scheduler, (_) async {}),
      );
      await cubit.load();
      await cubit.delete(repo.all.single);
      expect(repo.all, isNotEmpty);
      await cubit.commitPendingDelete();
      expect(repo.all, isEmpty);
      await cubit.close();
    },
  );
}

/// Records deletes; [gate] holds the next one until completed.
class _GatedRepository extends InMemoryRepository {
  _GatedRepository(super.reminders);
  Completer<void>? gate;
  final deleted = <String>[];

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    await gate?.future;
    await super.delete(id);
  }
}
