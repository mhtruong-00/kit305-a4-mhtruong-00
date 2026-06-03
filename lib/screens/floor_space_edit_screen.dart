// Floor Space add/edit form, ported from the iOS `FloorSpaceEditViewController`.
// Validates 1–20000 mm dimensions, selects a floor product/variant, attaches a
// gallery photo, and shows a live item-price preview.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/floor_space.dart';
import '../models/house.dart';
import '../models/product.dart';
import '../models/room.dart';
import '../services/firestore_service.dart';
import '../services/image_store.dart';
import '../services/photo_picker.dart';
import '../services/quote_calculator.dart';
import 'product_list_screen.dart';

class FloorSpaceEditScreen extends StatefulWidget {
  final House house;
  final Room room;
  final FloorSpace? floor; // null = add

  const FloorSpaceEditScreen({
    super.key,
    required this.house,
    required this.room,
    this.floor,
  });

  @override
  State<FloorSpaceEditScreen> createState() => _FloorSpaceEditScreenState();
}

class _FloorSpaceEditScreenState extends State<FloorSpaceEditScreen> {
  static const int _minMm = 1;
  static const int _maxMm = 20000;

  final _nameController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();

  Product? _selectedProduct;
  ProductVariant? _selectedVariant;

  Uint8List? _newImageBytes;
  String? _existingPhotoBase64;
  bool _saving = false;

  bool get _isEditing => widget.floor != null;

  @override
  void initState() {
    super.initState();
    final f = widget.floor;
    if (f != null) {
      _nameController.text = f.name;
      if (f.widthMm > 0) _widthController.text = '${f.widthMm}';
      if (f.depthMm > 0) _depthController.text = '${f.depthMm}';
      _existingPhotoBase64 = f.photoBase64;
      if (f.selectedProductId.isNotEmpty) {
        _selectedProduct =
            Product(id: f.selectedProductId, name: f.selectedProductName);
        if (f.selectedProductVariant.isNotEmpty) {
          _selectedVariant = ProductVariant(name: f.selectedProductVariant);
        }
      }
    }
    _widthController.addListener(_onChanged);
    _depthController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String get _productLabel {
    if (_selectedProduct == null) return 'No product selected';
    final variant = _selectedVariant;
    return variant == null || variant.name.isEmpty
        ? _selectedProduct!.name
        : '${_selectedProduct!.name} — ${variant.name}';
  }

  String get _priceLabel {
    final w = int.tryParse(_widthController.text);
    final d = int.tryParse(_depthController.text);
    if (w == null || d == null || w <= 0 || d <= 0 || _selectedProduct == null) {
      return 'Item price: —';
    }
    final area = (w / 1000.0) * (d / 1000.0);
    final rate = _selectedProduct!.pricePerSqm > 0
        ? _selectedProduct!.pricePerSqm
        : QuoteCalculator.defaultFloorRate;
    final price = rate * area;
    return 'Item price: \$${price.toStringAsFixed(2)} (${area.toStringAsFixed(4)} m²)';
  }

  Future<void> _selectProduct() async {
    final selection = await Navigator.push<ProductSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          category: 'floor',
          spaceWidthMm: int.tryParse(_widthController.text) ?? 0,
          spaceHeightMm: int.tryParse(_depthController.text) ?? 0,
        ),
      ),
    );
    if (selection != null) {
      setState(() {
        _selectedProduct = selection.product;
        _selectedVariant = selection.variant;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final bytes = await PhotoPicker.shared.pickFromGallery();
    if (bytes != null) {
      setState(() => _newImageBytes = bytes);
    }
  }

  void _removePhoto() {
    setState(() {
      _newImageBytes = null;
      _existingPhotoBase64 = null;
    });
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final width = int.tryParse(_widthController.text);
    if (width == null || width < _minMm || width > _maxMm) {
      _showAlert('Validation Error',
          'Width must be between $_minMm and $_maxMm mm.');
      return;
    }
    final depth = int.tryParse(_depthController.text);
    if (depth == null || depth < _minMm || depth > _maxMm) {
      _showAlert('Validation Error',
          'Depth must be between $_minMm and $_maxMm mm.');
      return;
    }

    final name = _nameController.text.trim().isEmpty
        ? 'Unnamed'
        : _nameController.text.trim();

    String? photoBase64 = _existingPhotoBase64;
    if (_newImageBytes != null) {
      photoBase64 = ImageStore.shared.encodeBytes(_newImageBytes!);
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final f = widget.floor!
          ..name = name
          ..widthMm = width
          ..depthMm = depth
          ..selectedProductId = _selectedProduct?.id ?? ''
          ..selectedProductName = _selectedProduct?.name ?? ''
          ..selectedProductVariant = _selectedVariant?.name ?? ''
          ..photoBase64 = photoBase64;
        await FirestoreService.shared.updateFloorSpace(f);
      } else {
        await FirestoreService.shared.addFloorSpace(FloorSpace(
          roomId: widget.room.id,
          name: name,
          widthMm: width,
          depthMm: depth,
          selectedProductId: _selectedProduct?.id ?? '',
          selectedProductName: _selectedProduct?.name ?? '',
          selectedProductVariant: _selectedVariant?.name ?? '',
          photoBase64: photoBase64,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showAlert('Error', e.toString());
      }
    }
  }

  Widget _photoPreview() {
    final bytes = _newImageBytes ??
        (_existingPhotoBase64 != null
            ? ImageStore.shared.decodeImage(_existingPhotoBase64!)
            : null);
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover, width: double.infinity)
          : const Center(child: Icon(Icons.photo, size: 48, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _newImageBytes != null || _existingPhotoBase64 != null;
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Edit Floor Space' : 'Add Floor Space')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Name'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    hintText: 'Floor space name (e.g. Main floor)'),
              ),
              const SizedBox(height: 16),
              const Text('Dimensions (mm)'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration:
                          const InputDecoration(hintText: 'Width (mm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _depthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration:
                          const InputDecoration(hintText: 'Depth (mm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Product'),
              const SizedBox(height: 6),
              Text(_productLabel),
              TextButton(
                onPressed: _selectProduct,
                child: const Text('Select Floor Product'),
              ),
              const SizedBox(height: 8),
              const Text('Photo'),
              const SizedBox(height: 6),
              _photoPreview(),
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Add Photo (Gallery)'),
              ),
              if (hasPhoto)
                TextButton(
                  onPressed: _removePhoto,
                  child: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 8),
              Text(_priceLabel,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Floor Space'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


