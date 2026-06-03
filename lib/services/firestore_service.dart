// Firestore data layer, ported from the iOS `FirestoreService`.
// Top-level collections (houses, rooms, windows, floorspaces) match the
// Android/iOS schema so all clients share the same database.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/floor_space.dart';
import '../models/house.dart';
import '../models/room.dart';
import '../models/window_item.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService shared = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // MARK: - Houses

  Stream<List<House>> housesStream() {
    return _db.collection('houses').snapshots().map(
        (snap) => snap.docs.map((d) => House.fromDoc(d)).toList());
  }

  Future<void> addHouse(House house) =>
      _db.collection('houses').add(house.toData());

  Future<void> updateHouse(House house) =>
      _db.collection('houses').doc(house.id).update(house.toData());

  /// Deletes the house and all of its rooms (and their items) — matches the
  /// iOS/Android cascade behaviour.
  Future<void> deleteHouse(String houseId) async {
    final roomsSnap = await _db
        .collection('rooms')
        .where('houseId', isEqualTo: houseId)
        .get();
    final roomIds = roomsSnap.docs.map((d) => d.id).toList();

    final batch = _db.batch();
    for (final roomId in roomIds) {
      batch.delete(_db.collection('rooms').doc(roomId));
    }
    batch.delete(_db.collection('houses').doc(houseId));
    await batch.commit();

    // Best-effort cleanup of nested windows/floorspaces.
    for (final rid in roomIds) {
      for (final coll in ['windows', 'floorspaces']) {
        final itemsSnap =
            await _db.collection(coll).where('roomId', isEqualTo: rid).get();
        final inner = _db.batch();
        for (final doc in itemsSnap.docs) {
          inner.delete(doc.reference);
        }
        await inner.commit();
      }
    }
  }

  // MARK: - Rooms

  Stream<List<Room>> roomsStream(String houseId) {
    return _db
        .collection('rooms')
        .where('houseId', isEqualTo: houseId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Room.fromDoc(d)).toList());
  }

  Future<void> addRoom(Room room) =>
      _db.collection('rooms').add(room.toData());

  Future<void> updateRoom(Room room) =>
      _db.collection('rooms').doc(room.id).update(room.toData());

  Future<void> updateRoomFields(String roomId, Map<String, dynamic> fields) =>
      _db.collection('rooms').doc(roomId).update(fields);

  Future<void> deleteRoom(String roomId) async {
    // Cascade-delete the room's windows/floorspaces.
    for (final coll in ['windows', 'floorspaces']) {
      final snap =
          await _db.collection(coll).where('roomId', isEqualTo: roomId).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _db.collection('rooms').doc(roomId).delete();
  }

  /// Duplicate a room (and all of its windows + floor spaces) into a new
  /// "<name> (Copy)" room. Saves users retyping every measurement when a
  /// layout repeats (e.g. identical bedrooms).
  Future<void> duplicateRoom(Room room) async {
    final copy = Room(
      houseId: room.houseId,
      name: '${room.name} (Copy)',
      photoBase64: room.photoBase64,
      photoUrl: room.photoUrl,
    );
    final newRef = _db.collection('rooms').doc();
    await newRef.set(copy.toData());
    final newRoomId = newRef.id;

    // Copy windows.
    final windowsSnap =
        await _db.collection('windows').where('roomId', isEqualTo: room.id).get();
    final wBatch = _db.batch();
    for (final doc in windowsSnap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['roomId'] = newRoomId;
      wBatch.set(_db.collection('windows').doc(), data);
    }
    await wBatch.commit();

    // Copy floor spaces.
    final floorsSnap = await _db
        .collection('floorspaces')
        .where('roomId', isEqualTo: room.id)
        .get();
    final fBatch = _db.batch();
    for (final doc in floorsSnap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['roomId'] = newRoomId;
      fBatch.set(_db.collection('floorspaces').doc(), data);
    }
    await fBatch.commit();
  }

  // MARK: - Windows

  Stream<List<WindowItem>> windowsStream(String roomId) {
    return _db
        .collection('windows')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WindowItem.fromDoc(d)).toList());
  }

  Future<void> addWindow(WindowItem window) =>
      _db.collection('windows').add(window.toData());

  Future<void> updateWindow(WindowItem window) =>
      _db.collection('windows').doc(window.id).update(window.toData());

  Future<void> deleteWindow(String windowId) =>
      _db.collection('windows').doc(windowId).delete();

  // MARK: - Floor Spaces

  Stream<List<FloorSpace>> floorSpacesStream(String roomId) {
    return _db
        .collection('floorspaces')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FloorSpace.fromDoc(d)).toList());
  }

  Future<void> addFloorSpace(FloorSpace floor) =>
      _db.collection('floorspaces').add(floor.toData());

  Future<void> updateFloorSpace(FloorSpace floor) =>
      _db.collection('floorspaces').doc(floor.id).update(floor.toData());

  Future<void> deleteFloorSpace(String floorId) =>
      _db.collection('floorspaces').doc(floorId).delete();

  // MARK: - Quote loader

  /// Loads the rooms, windows and floor spaces for a house in a single
  /// composite operation, used by the Quote screen.
  Future<QuoteData> loadQuoteData(String houseId) async {
    final roomSnap = await _db
        .collection('rooms')
        .where('houseId', isEqualTo: houseId)
        .get();
    final rooms = roomSnap.docs.map((d) => Room.fromDoc(d)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (rooms.isEmpty) {
      return QuoteData(rooms: [], windowsByRoom: {}, floorsByRoom: {});
    }

    final windowsByRoom = <String, List<WindowItem>>{};
    final floorsByRoom = <String, List<FloorSpace>>{};

    for (final r in rooms) {
      final wSnap = await _db
          .collection('windows')
          .where('roomId', isEqualTo: r.id)
          .get();
      windowsByRoom[r.id] =
          wSnap.docs.map((d) => WindowItem.fromDoc(d)).toList();

      final fSnap = await _db
          .collection('floorspaces')
          .where('roomId', isEqualTo: r.id)
          .get();
      floorsByRoom[r.id] =
          fSnap.docs.map((d) => FloorSpace.fromDoc(d)).toList();
    }

    return QuoteData(
      rooms: rooms,
      windowsByRoom: windowsByRoom,
      floorsByRoom: floorsByRoom,
    );
  }
}

/// Bundle returned by [FirestoreService.loadQuoteData].
class QuoteData {
  final List<Room> rooms;
  final Map<String, List<WindowItem>> windowsByRoom;
  final Map<String, List<FloorSpace>> floorsByRoom;

  QuoteData({
    required this.rooms,
    required this.windowsByRoom,
    required this.floorsByRoom,
  });
}

