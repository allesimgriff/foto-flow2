import 'dart:io' show File;

import 'package:flutter/material.dart';

Widget savedPhotoFileImage(String filePath) {
  return Image.file(
    File(filePath),
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return ColoredBox(
        color: Colors.grey.shade300,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey.shade600,
          ),
        ),
      );
    },
  );
}
