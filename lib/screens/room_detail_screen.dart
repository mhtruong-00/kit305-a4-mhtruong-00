// Room detail screen, ported from the iOS `RoomDetailViewController`.
// Shows a room cover photo header plus two sections (Windows and Floor Spaces)
// with add/edit/delete. The cover photo is picked from the gallery.
import 'package:flutter/material.dart';

import '../models/floor_space.dart';
import '../models/house.dart';
import '../models/room.dart';
import '../models/window_item.dart';
import '../services/firestore_service.dart';
import '../services/image_store.dart';
import '../services/photo_picker.dart';
import '../theme/app_theme.dart';
import 'floor_space_edit_screen.dart';
import 'window_edit_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final House house;
  final Room room;

  const RoomDetailScreen({super.key, required this.house, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Room _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
  }

  Future<void> _pickRoomPhoto() async {
    final bytes = await PhotoPicker.shared.pickFromGallery();
    if (bytes == null) return;
    final base64 = ImageStore.shared.encodeBytes(bytes);
    try {
      await FirestoreService.shared
          .updateRoomFields(_room.id, {'photoBase64': base64});
      setState(() => _room.photoBase64 = base64);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _removeRoomPhoto() async {
    await FirestoreService.shared
        .updateRoomFields(_room.id, {'photoBase64': '', 'photoUrl': ''});
    setState(() {
      _room.photoBase64 = null;
      _room.photoUrl = null;
    });
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _room.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Room'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      _room.name = name;
      await FirestoreService.shared.updateRoom(_room);
      setState(() {});
    }
  }

  Widget _coverPhoto() {
    final bytes = _room.photoBase64 == null
        ? null
        : ImageStore.shared.decodeImage(_room.photoBase64!);
    return Column(
      children: [
        Container(
          height: 130,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover)
              : const Center(
                  child: Icon(Icons.photo, size: 48, color: Colors.grey)),
        ),
        if (bytes != null)
          TextButton(
            onPressed: _removeRoomPhoto,
            child: const Text('Remove Photo',
                style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteWindow(WindowItem w) async {
    final ok = await _confirm('Delete Window', 'Delete this window?');
    if (ok) await FirestoreService.shared.deleteWindow(w.id);
  }

  Future<void> _confirmDeleteFloor(FloorSpace f) async {
    final ok = await _confirm('Delete Floor Space', 'Delete this floor space?');
    if (ok) await FirestoreService.shared.deleteFloorSpace(f.id);
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_room.name),
        actions: [
          IconButton(
            tooltip: 'Room Photo',
            icon: const Icon(Icons.photo_outlined),
            onPressed: _pickRoomPhoto,
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed: _rename,
          ),
        ],
      ),
      body: ListView(
        children: [
          _coverPhoto(),
          // Windows section
          StreamBuilder<List<WindowItem>>(
            stream: FirestoreService.shared.windowsStream(_room.id),
            builder: (context, snap) {
              final windows = snap.data ?? [];
              return _section(
                title: windows.isEmpty
                    ? 'Windows (none)'
                    : 'Windows (${windows.length})',
                tint: AppColors.windowTint,
                addLabel: '+ Add Window',
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WindowEditScreen(
                        house: widget.house, room: _room),
                  ),
                ),
                children: [
                  for (final w in windows)
                    Dismissible(
                      key: ValueKey('w_${w.id}'),
                      direction: DismissDirection.endToStart,
                      background: _deleteBg(),
                      confirmDismiss: (_) async {
                        await _confirmDeleteWindow(w);
                        return false;
                      },
                      child: ListTile(
                        title: Text(w.name.isEmpty ? 'Unnamed' : w.name),
                        subtitle: Text(
                            '${w.widthMm}W × ${w.heightMm}H mm'
                            '${w.selectedProductName.isNotEmpty ? ' • ${w.selectedProductName}' : ''}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WindowEditScreen(
                                house: widget.house,
                                room: _room,
                                window: w),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Floor spaces section
          StreamBuilder<List<FloorSpace>>(
            stream: FirestoreService.shared.floorSpacesStream(_room.id),
            builder: (context, snap) {
              final floors = snap.data ?? [];
              return _section(
                title: floors.isEmpty
                    ? 'Floor Spaces (none)'
                    : 'Floor Spaces (${floors.length})',
                tint: AppColors.floorTint,
                addLabel: '+ Add Floor Space',
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FloorSpaceEditScreen(
                        house: widget.house, room: _room),
                  ),
                ),
                children: [
                  for (final f in floors)
                    Dismissible(
                      key: ValueKey('f_${f.id}'),
                      direction: DismissDirection.endToStart,
                      background: _deleteBg(),
                      confirmDismiss: (_) async {
                        await _confirmDeleteFloor(f);
                        return false;
                      },
                      child: ListTile(
                        title: Text(f.name.isEmpty ? 'Unnamed' : f.name),
                        subtitle: Text(
                            '${f.widthMm}W × ${f.depthMm}D mm'
                            '${f.selectedProductName.isNotEmpty ? ' • ${f.selectedProductName}' : ''}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FloorSpaceEditScreen(
                                house: widget.house,
                                room: _room,
                                floor: f),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _deleteBg() => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      );

  Widget _section({
    required String title,
    required Color tint,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: tint)),
        ),
        ...children,
        Center(
          child: TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(foregroundColor: tint),
            child: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

