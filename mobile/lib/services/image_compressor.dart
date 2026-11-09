import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  static Future<Uint8List> compressImage(Uint8List list) async {
    if (kIsWeb) return list;
    try {
      final result = await FlutterImageCompress.compressWithList(
        list,
        minHeight: 1080,
        minWidth: 1920,
        quality: 85,
      );
      return result.isNotEmpty ? result : list;
    } catch (_) {
      return list;
    }
  }
}
