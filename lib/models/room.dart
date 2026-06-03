// Model for a Room within a house.
// Top-level "rooms" collection. Fields: houseId, name, photoBase64, photoUrl.
import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  String id;
  String houseId;
  String name;
  String? photoBase64;
  String? photoUrl;

  Room({
    this.id = '',
    this.houseId = '',
    this.name = '',
    this.photoBase64,
    this.photoUrl,
  });

  factory Room.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    String? nilIfEmpty(dynamic v) {
      final s = v as String?;
      return (s == null || s.isEmpty) ? null : s;
    }

    return Room(
      id: doc.id,
      houseId: data['houseId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      photoBase64: nilIfEmpty(data['photoBase64']),
      photoUrl: nilIfEmpty(data['photoUrl']),
    );
  }

  Map<String, dynamic> toData() {
    return {
      'houseId': houseId,
      'name': name,
      'photoBase64': photoBase64 ?? '',
      'photoUrl': photoUrl ?? '',
    };
  }
}

