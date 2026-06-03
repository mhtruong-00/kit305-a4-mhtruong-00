// House list screen, ported from the iOS `HouseListViewController`.
// Live Firestore list with search, add, swipe edit/delete, and a Quote action.
import 'package:flutter/material.dart';

import '../models/house.dart';
import '../services/firestore_service.dart';
import 'house_edit_screen.dart';
import 'quote_screen.dart';
import 'room_list_screen.dart';

class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  String _query = '';

  List<House> _filter(List<House> houses) {
    if (_query.isEmpty) return houses;
    final q = _query.toLowerCase();
    return houses
        .where((h) =>
            h.name.toLowerCase().contains(q) ||
            h.address.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _confirmDelete(House house) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete House'),
        content: Text('Delete "${house.name}"? This cannot be undone.'),
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
        await FirestoreService.shared.deleteHouse(house.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  void _openEdit([House? house]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HouseEditScreen(house: house)),
    );
  }

  Future<void> _openQuotePicker(List<House> houses) async {
    if (houses.isEmpty) return;
    final selected = await showModalBottomSheet<House>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select House for Quote',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final h in houses)
              ListTile(
                title: Text(h.name),
                subtitle: Text(h.address),
                onTap: () => Navigator.pop(ctx, h),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => QuoteScreen(house: selected)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<House>>(
      stream: FirestoreService.shared.housesStream(),
      builder: (context, snapshot) {
        final houses = snapshot.data ?? [];
        final displayed = _filter(houses);
        return Scaffold(
          appBar: AppBar(
            title: Text('Houses (${houses.length})'),
            actions: [
              IconButton(
                tooltip: 'Quote',
                icon: const Icon(Icons.request_quote_outlined),
                onPressed: () => _openQuotePicker(houses),
              ),
              IconButton(
                tooltip: 'Add House',
                icon: const Icon(Icons.add),
                onPressed: () => _openEdit(),
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
                    hintText: 'Search houses',
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : displayed.isEmpty
                        ? const Center(
                            child: Text(
                              'No houses yet.\nTap + to add your first house.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: displayed.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final house = displayed[index];
                              return Dismissible(
                                key: ValueKey(house.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  await _confirmDelete(house);
                                  return false; // stream refreshes the list
                                },
                                child: ListTile(
                                  title: Text(house.name),
                                  subtitle: Text(
                                    [
                                      house.address,
                                      if (house.notes.trim().isNotEmpty)
                                        '📝 ${house.notes.trim()}',
                                    ].join('\n'),
                                  ),
                                  isThreeLine: house.notes.trim().isNotEmpty,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openEdit(house),
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RoomListScreen(house: house),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}


