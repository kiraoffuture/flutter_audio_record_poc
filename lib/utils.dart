import 'dart:io';

import 'package:flutter/services.dart';

abstract class Utils {
  static Future<File> copyAssetToFile(
    String directoryPath,
    String assetPath,
    String fileName,
  ) async {
    final byteData = await rootBundle.load(assetPath);
    final file = File('$directoryPath/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }
}
