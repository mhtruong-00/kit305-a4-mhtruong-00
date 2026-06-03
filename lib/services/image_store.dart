// Base64 encode/decode helper for storing photos inside Firestore documents,
// matching the iOS `ImageStore` behaviour (store base64 JPEG in the document
// instead of using Firebase Storage).
//
// Downscaling + JPEG compression is performed by `image_picker` at capture
// time (maxWidth / imageQuality), which keeps the encoded payload comfortably
// under the Firestore single-field limit (target < ~250 KB).
import 'dart:convert';
import 'dart:typed_data';

class ImageStore {
  ImageStore._();
  static final ImageStore shared = ImageStore._();

  /// Encode already-compressed JPEG [bytes] to a base64 string.
  String encodeBytes(Uint8List bytes) => base64Encode(bytes);

  /// Decode a base64 string back to raw bytes for `Image.memory`.
  Uint8List? decodeImage(String base64String) {
    if (base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }
}


