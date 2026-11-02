import 'dart:typed_data';
import 'api_service.dart';
import 'image_compressor.dart';

class ImageUploadService {
  static final ImageUploadService instance = ImageUploadService._init();
  ImageUploadService._init();

  Future<String?> uploadImageBytes(List<int> bytes, {String filename = 'photo.jpg'}) async {
    try {
      final compressed = await ImageCompressor.compressImage(Uint8List.fromList(bytes));
      final res = await ApiService().post('/upload', data: {
        'filename': filename,
        'image': compressed,
      });
      if (res.data != null && res.data['url'] != null) {
        return res.data['url'].toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
