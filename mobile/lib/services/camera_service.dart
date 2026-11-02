import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'image_compressor.dart';

class CameraService {
  static final CameraService instance = CameraService._init();
  final ImagePicker _picker = ImagePicker();

  CameraService._init();

  Future<String> _saveLocally(Uint8List bytes) async {
    if (kIsWeb) {
      return 'base64:${base64Encode(bytes)}';
    }
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  Future<String?> capturePhotoFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo == null) return null;

      final bytes = await photo.readAsBytes();
      
      Uint8List finalBytes;
      if (kIsWeb) {
        finalBytes = bytes;
      } else {
        finalBytes = await ImageCompressor.compressImage(bytes);
      }
      
      return await _saveLocally(finalBytes);
    } catch (e) {
      if (kDebugMode) print('Camera capture error: $e');
      return null;
    }
  }

  Future<List<String>> pickMultipleFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isEmpty) return [];

      final List<String> paths = [];
      for (var img in images) {
        final bytes = await img.readAsBytes();
        final compressed = await ImageCompressor.compressImage(bytes);
        paths.add(await _saveLocally(compressed));
      }
      return paths;
    } catch (e) {
      if (kDebugMode) print('Gallery pick error: $e');
      return [];
    }
  }
}
