import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Alle lokal gespeicherten Fotos unter `foto_flow2_photos/`
/// (`ohne_album`, Album-Unterordner), sortiert nach vollem Pfad.
Future<List<String>> listSavedPhotoPaths() async {
  final base = await getApplicationDocumentsDirectory();
  final root = Directory('${base.path}/foto_flow2_photos');
  if (!await root.exists()) return [];

  final out = <String>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      out.add(entity.path);
    }
  }
  out.sort();
  return out;
}
