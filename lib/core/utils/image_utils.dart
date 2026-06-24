import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;

/// Runs image-orientation fixing in an isolate to avoid blocking the UI.
/// Designed to be used with [compute] from `package:flutter/foundation.dart`.
Uint8List fixImageOrientationIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final oriented = img.bakeOrientation(decoded);
  return Uint8List.fromList(img.encodeJpg(oriented, quality: 95));
}
