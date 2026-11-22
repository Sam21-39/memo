import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Media files named by reminder id under `<documents>/media/`.
///
/// On iOS a clip that rings must also sit in Library/Sounds and be under
/// 30 s; [installSound] / [removeSound] keep that copy in step.
class MediaStore {
  MediaStore(this._dir, {this.installSound, this.removeSound});

  final Directory _dir;
  final Future<void> Function(String path, String id)? installSound;
  final Future<void> Function(String id)? removeSound;

  static Future<MediaStore> open({
    Future<void> Function(String path, String id)? installSound,
    Future<void> Function(String id)? removeSound,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'media'));
    await dir.create(recursive: true);
    final store = MediaStore(
      dir,
      installSound: installSound,
      removeSound: removeSound,
    );
    await store.recoverBackups();
    return store;
  }

  /// A kill between [commitVoice]'s two renames leaves only `<id>.bak.wav`:
  /// put the replaced clip back.
  Future<void> recoverBackups() async {
    await for (final f in _dir.list()) {
      final name = p.basename(f.path);
      if (f is! File || !name.endsWith('.bak.wav')) continue;
      final id = name.substring(0, name.length - '.bak.wav'.length);
      if (await File(voicePath(id)).exists()) continue;
      await f.rename(voicePath(id));
      await installSound?.call(voicePath(id), id);
    }
  }

  String voicePath(String id) => p.join(_dir.path, '$id.wav');

  String imagePath(String id) => p.join(_dir.path, '$id.jpg');

  /// Where a clip records before its reminder is saved.
  String get draftVoicePath => p.join(_dir.path, 'draft.wav');

  /// Where a take records; it replaces [draftVoicePath] only when kept.
  String get draftTempPath => p.join(_dir.path, 'draft.rec.wav');

  String _backupPath(String id) => p.join(_dir.path, '$id.bak.wav');

  /// Moves a recorded draft to the reminder's clip and installs it as a
  /// sound. A clip already there is kept as a backup until [dropBackup] or
  /// [uncommitVoice]. Returns false when there was no draft.
  Future<bool> commitVoice(String id) async {
    final draft = File(draftVoicePath);
    if (!await draft.exists()) return false;
    final old = File(voicePath(id));
    try {
      if (await old.exists()) await old.rename(_backupPath(id));
      await draft.rename(voicePath(id));
      await installSound?.call(voicePath(id), id);
    } catch (_) {
      // No half-moved state: the draft and the old clip go back.
      await uncommitVoice(id);
      rethrow;
    }
    return true;
  }

  /// The save went through: the replaced clip is no longer needed.
  Future<void> dropBackup(String id) async {
    final backup = File(_backupPath(id));
    if (await backup.exists()) await backup.delete();
  }

  bool get hasDraft => File(draftVoicePath).existsSync();

  /// Undoes [commitVoice] when the reminder did not save: the new clip goes
  /// back to the draft and the replaced clip, if any, is restored.
  Future<void> uncommitVoice(String id) async {
    final clip = File(voicePath(id));
    if (await clip.exists()) await clip.rename(draftVoicePath);
    final backup = File(_backupPath(id));
    if (await backup.exists()) {
      await backup.rename(voicePath(id));
      await installSound?.call(voicePath(id), id);
    } else {
      await removeSound?.call(id);
    }
  }

  Future<void> discardDraft() async {
    final draft = File(draftVoicePath);
    if (await draft.exists()) await draft.delete();
  }

  Future<void> deleteVoice(String id) async {
    final file = File(voicePath(id));
    if (await file.exists()) await file.delete();
    final backup = File(_backupPath(id));
    if (await backup.exists()) await backup.delete();
    await removeSound?.call(id);
  }

  Future<void> deleteFor(String id) async {
    await deleteVoice(id);
    final image = File(imagePath(id));
    if (await image.exists()) await image.delete();
  }

  /// "0:08". WAV 16 kHz mono 16-bit is 32 000 bytes a second after a
  /// 44-byte header, so the length needs no decoder.
  static String clipLength(String path) {
    final file = File(path);
    final bytes = file.existsSync() ? file.lengthSync() : 0;
    final seconds = ((bytes - 44).clamp(0, 1 << 30) / 32000).round();
    return '0:${seconds.toString().padLeft(2, '0')}';
  }
}
