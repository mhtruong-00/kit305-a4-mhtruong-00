// House add/edit form, ported from the iOS `HouseEditViewController`.
// Validates: name required; address required and must contain at least one
// letter (matches the Android validation).
import 'package:flutter/material.dart';

import '../models/house.dart';
import '../services/firestore_service.dart';

class HouseEditScreen extends StatefulWidget {
  /// When null, this is an "add" form; otherwise an "edit" form.
  final House? house;

  const HouseEditScreen({super.key, this.house});

  @override
  State<HouseEditScreen> createState() => _HouseEditScreenState();
}

class _HouseEditScreenState extends State<HouseEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  bool _saving = false;

  bool get _isEditing => widget.house != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.house?.name ?? '');
    _addressController =
        TextEditingController(text: widget.house?.address ?? '');
    _notesController = TextEditingController(text: widget.house?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showAlert('Name Required',
          'Please enter a customer name before saving.');
      return;
    }
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showAlert('Address Required', 'Please enter an address.');
      return;
    }
    // Address must contain at least one letter (prevents "12345").
    if (!address.contains(RegExp(r'[A-Za-z]'))) {
      _showAlert('Invalid Address', 'Address must contain at least one letter.');
      return;
    }

    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      if (_isEditing) {
        final updated = widget.house!
          ..name = name
          ..address = address
          ..notes = _notesController.text;
        await FirestoreService.shared.updateHouse(updated);
      } else {
        await FirestoreService.shared.addHouse(
          House(name: name, address: address, notes: _notesController.text),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Saved changes to "$name".'
                : 'Added "$name".'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showAlert('Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit House' : 'Add House')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Customer / House Name'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    hintText: 'Customer / House Name'),
              ),
              const SizedBox(height: 16),
              const Text('Address'),
              const SizedBox(height: 6),
              TextField(
                controller: _addressController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Address'),
              ),
              const SizedBox(height: 16),
              const Text('Notes (optional)'),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. preferred install date, style preferences, contact details…',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
              TextButton(
                onPressed:
                    _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


