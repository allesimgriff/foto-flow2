import 'package:flutter/material.dart';

/// Web: kein Dateizugriff — neutraler Platzhalter gleicher Rolle wie fehlende Datei.
Widget savedPhotoFileImage(String filePath) {
  return ColoredBox(
    color: Colors.grey.shade300,
    child: Center(
      child: Icon(
        Icons.photo_outlined,
        size: 48,
        color: Colors.grey.shade600,
      ),
    ),
  );
}
