// Gallery photo picker helper, ported from the iOS `PhotoPickerCoordinator`.
//
// Per the Assignment 4 CRA update, ONLY photo-gallery selection is required
// (the iOS simulator has no camera), so this picks from the gallery and
// downscales/compresses at capture time so the base64 payload stays small
// enough to live inside a Firestore document.
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PhotoPicker {
  PhotoPicker._();
  static final PhotoPicker shared = PhotoPicker._();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from the photo gallery, returning compressed JPEG bytes
  /// (or null if the user cancelled). Downscaled to max 1280px / quality 70
  /// to stay under the Firestore field-size limit once base64-encoded.
  Future<Uint8List?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}

