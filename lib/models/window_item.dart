// Model for a Window within a room.
// Top-level "windows" collection. Fields: roomId, name, widthMm, heightMm,
// selectedProductId, selectedProductName, selectedProductVariant, panelCount,
// photoBase64.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_coerce.dart';

class WindowItem {
  String id;
  String roomId;
  String name;
  int widthMm;
  int heightMm;
  String selectedProductId;
  String selectedProductName;
  String selectedProductVariant;
  int panelCount;
  String? photoBase64;

  WindowItem({
    this.id = '',
    this.roomId = '',
    this.name = '',
    this.widthMm = 0,
    this.heightMm = 0,
    this.selectedProductId = '',
    this.selectedProductName = '',
    this.selectedProductVariant = '',
    this.panelCount = 1,
    this.photoBase64,
  });

  /// Area in m derived from millimetres.
  double get areaSqm => (widthMm / 1000.0) * (heightMm / 1000.0);

  factory WindowItem.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    String? nilIfEmpty(dynamic v) {
      final s = v as String?;
      return (s == null || s.isEmpty) ? null : s;
    }

    return WindowItem(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      widthMm: coerceInt(data['widthMm']),
      heightMm: coerceInt(data['heightMm']),
      selectedProductId: data['selectedProductId'] as String? ?? '',
      selectedProductName: data['selectedProductName'] as String? ?? '',
      selectedProductVariant: data['selectedProductVariant'] as String? ?? '',
      panelCount: coerceInt(data['panelCount'], fallback: 1),
      photoBase64: nilIfEmpty(data['photoBase64']),
    );
  }

  Map<String, dynamic> toData() {
    return {
      'roomId': roomId,
      'name': name,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'selectedProductId': selectedProductId,
      'selectedProductName': selectedProductName,
      'selectedProductVariant': selectedProductVariant,
      'panelCount': panelCount,
      'photoBase64': photoBase64 ?? '',
    };
  }
}

