// Model for a Floor Space within a room.
// Top-level "floorspaces" collection. Fields: roomId, name, widthMm, depthMm,
// selectedProductId, selectedProductName, selectedProductVariant, photoBase64.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_coerce.dart';

class FloorSpace {
  String id;
  String roomId;
  String name;
  int widthMm;
  int depthMm;
  String selectedProductId;
  String selectedProductName;
  String selectedProductVariant;
  String? photoBase64;

  FloorSpace({
    this.id = '',
    this.roomId = '',
    this.name = '',
    this.widthMm = 0,
    this.depthMm = 0,
    this.selectedProductId = '',
    this.selectedProductName = '',
    this.selectedProductVariant = '',
    this.photoBase64,
  });

  double get areaSqm => (widthMm / 1000.0) * (depthMm / 1000.0);

  factory FloorSpace.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    String? nilIfEmpty(dynamic v) {
      final s = v as String?;
      return (s == null || s.isEmpty) ? null : s;
    }

    return FloorSpace(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      widthMm: coerceInt(data['widthMm']),
      depthMm: coerceInt(data['depthMm']),
      selectedProductId: data['selectedProductId'] as String? ?? '',
      selectedProductName: data['selectedProductName'] as String? ?? '',
      selectedProductVariant: data['selectedProductVariant'] as String? ?? '',
      photoBase64: nilIfEmpty(data['photoBase64']),
    );
  }

  Map<String, dynamic> toData() {
    return {
      'roomId': roomId,
      'name': name,
      'widthMm': widthMm,
      'depthMm': depthMm,
      'selectedProductId': selectedProductId,
      'selectedProductName': selectedProductName,
      'selectedProductVariant': selectedProductVariant,
      'photoBase64': photoBase64 ?? '',
    };
  }
}

