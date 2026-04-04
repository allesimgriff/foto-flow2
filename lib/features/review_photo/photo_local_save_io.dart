import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> saveCapturedPhotoToAppDir(
  String capturedFilePath,
  String? activeAlbumName,
) async {
  final src = File(capturedFilePath);
  if (!await src.exists()) return;

  final base = await getApplicationDocumentsDirectory();
  final segment = _albumFolderSegment(activeAlbumName);
  final dir = Directory('${base.path}/foto_flow2_photos/$segment');
  await dir.create(recursive: true);

  final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final dest = File('${dir.path}/$fileName');
  await src.copy(dest.path);
}

String _albumFolderSegment(String? name) {
  if (name == null || name.trim().isEmpty) return 'ohne_album';
  var s = name.trim().replaceAll(RegExp(r'[/\\?%*:|"<>.\x00-\x1f]'), '_');
  if (s.isEmpty || s == '.' || s == '..') return 'album';
  return s;
}
