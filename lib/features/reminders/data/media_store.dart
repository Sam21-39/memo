import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Media files named by reminder id under `<documents>/media/`.
class MediaStore {
  MediaStore(this._dir);

  final Directory _dir;

  static Future<MediaStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'media'));
    await dir.create(recursive: true);
    return MediaStore(dir);
  }

  String voicePath(String id) => p.join(_dir.path, '$id.wav');

  String imagePath(String id) => p.join(_dir.path, '$id.jpg');

  Future<void> deleteFor(String id) async {
    for (final path in [voicePath(id), imagePath(id)]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }
}
