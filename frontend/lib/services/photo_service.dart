import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image and returns it as a base64 data URI, ready to send
  /// straight into `photo_url`. Caps the longest side at 800px to keep
  /// payload size reasonable since there's no dedicated upload endpoint.
  Future<String?> pickPhotoAsDataUri() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final String mime = _mimeFromExtension(file.name);
    final String base64Str = base64Encode(bytes);
    return 'data:$mime;base64,$base64Str';
  }

  String _mimeFromExtension(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
