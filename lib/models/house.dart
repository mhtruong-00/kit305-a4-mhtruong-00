// Model for a House (customer job site).
// Firestore document fields: `customerName`, `address`, `notes`.
// Mirrors the iOS `House` struct and the Android schema so all clients share
// the same database.
import 'package:cloud_firestore/cloud_firestore.dart';

class House {
  String id;
  String name; // stored in Firestore as "customerName"
  String address;
  String notes;

  House({
    this.id = '',
    this.name = '',
    this.address = '',
    this.notes = '',
  });

  /// Build a House from a Firestore document snapshot.
  factory House.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return House(
      id: doc.id,
      name: data['customerName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
    );
  }

  /// Convert to the Firestore field map.
  Map<String, dynamic> toData() {
    return {
      'customerName': name,
      'address': address,
      'notes': notes,
    };
  }
}

