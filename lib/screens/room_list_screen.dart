// Room list screen, ported from the iOS `RoomListViewController`.
// Live rooms list with search, add (dialog), rename, duplicate, delete, and a
// Quote action. Rows show a thumbnail decoded from the room's base64 photo.
import 'package:flutter/material.dart';

import '../models/house.dart';
import '../models/room.dart';
import '../services/firestore_service.dart';
import '../services/image_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_snack.dart';
import '../widgets/loading_indicator.dart';
import 'quote_screen.dart';
import 'room_detail_screen.dart';

class RoomListScreen extends StatefulWidget {
  final House house;

  const RoomListScreen({super.key, required this.house});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  String _query = '';

  List<Room> _filter(List<Room> rooms) {
    if (_query.isEmpty) return rooms;
    final q = _query.toLowerCase();
    return rooms.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  Future<String?> _promptName({String title = 'Add Room', String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Room name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoom() async {
    final name = await _promptName();
    if (name == null || name.isEmpty) return;
    await FirestoreService.shared
        .addRoom(Room(houseId: widget.house.id, name: name));
  }

  Future<void> _renameRoom(Room room) async {
    final name =
        await _promptName(title: 'Rename Room', initial: room.name);
    if (name == null || name.isEmpty) return;
    room.name = name;
    await FirestoreService.shared.updateRoom(room);
  }

  Future<void> _duplicateRoom(Room room) async {
    try {
      await FirestoreService.shared.duplicateRoom(room);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duplicated "${room.name}"')));
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e, prefix: "Couldn't duplicate");
      }
    }
  }

  Future<void> _confirmDelete(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete "${room.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final backup =
            await FirestoreService.shared.deleteRoomWithBackup(room);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Deleted "${room.name}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await FirestoreService.shared.restoreRoom(backup);
                } catch (e) {
                  if (mounted) {
                    showErrorSnack(context, e, prefix: "Couldn't restore");
                  }
                }
              },
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          showErrorSnack(context, e, prefix: "Couldn't delete");
        }
      }
    }
  }

  Widget _thumbnail(Room room) {
    final bytes = room.photoBase64 == null
        ? null
        : ImageStore.shared.decodeImage(room.photoBase64!);
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover)
          : const Icon(Icons.meeting_room_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.house.name),
        actions: [
          IconButton(
            tooltip: 'Quote',
            icon: const Icon(Icons.request_quote_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => QuoteScreen(house: widget.house)),
            ),
          ),
          IconButton(
            tooltip: 'Add Room',
            icon: const Icon(Icons.add),
            onPressed: _addRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search rooms',
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: FirestoreService.shared.roomsStream(widget.house.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Loading rooms…');
                }
                final rooms = _filter(snapshot.data ?? []);
                if (rooms.isEmpty) {
                  return const EmptyState(
                    icon: Icons.meeting_room_outlined,
                    message: 'No rooms yet.\nTap + to add a room.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    // Live stream keeps data fresh; give pull-to-refresh feedback.
                    await Future<void>.delayed(
                        const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    itemCount: rooms.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Dismissible(
                      key: ValueKey(room.id),
                      background: Container(
                        color: Colors.teal,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.copy, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Leading swipe → duplicate
                          await _duplicateRoom(room);
                          return false;
                        } else {
                          // Trailing swipe → delete
                          await _confirmDelete(room);
                          return false;
                        }
                      },
                      child: ListTile(
                        leading: _thumbnail(room),
                        title: Text(room.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.drive_file_rename_outline),
                          onPressed: () => _renameRoom(room),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailScreen(
                                house: widget.house, room: room),
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}










