import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows an activity photo: a Supabase Storage URL, or a just-picked image
/// (a file path on mobile/desktop, a blob URL on web).
class LocalImage extends StatelessWidget {
  const LocalImage(this.path, {super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    Widget error(BuildContext _, Object _, StackTrace? _) =>
        const ColoredBox(color: Color(0xFFD9D9D9));
    return kIsWeb || path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover, errorBuilder: error)
        : Image.file(File(path), fit: BoxFit.cover, errorBuilder: error);
  }
}
