// Window add/edit form, ported from the iOS `WindowEditViewController`.
// Validates 1–20000 mm dimensions, selects a product/variant, attaches a
// gallery photo, and shows a live item-price preview.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/house.dart';
import '../models/product.dart';
import '../models/room.dart';
import '../models/window_item.dart';
import '../services/firestore_service.dart';
import '../services/image_store.dart';
import '../services/photo_picker.dart';
import '../services/quote_calculator.dart';
import 'product_list_screen.dart';

class WindowEditScreen extends StatefulWidget {
  final House house;
  final Room room;
  final WindowItem? window; // null = add

  const WindowEditScreen({
    super.key,
    required this.house,
    required this.room,
    this.window,
  });

  @override
  State<WindowEditScreen> createState() => _WindowEditScreenState();
}

class _WindowEditScreenState extends State<WindowEditScreen> {
  static const int _minMm = 1;
  static const int _maxMm = 20000;

  final _nameController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  Product? _selectedProduct;
  ProductVariant? _selectedVariant;
  int _selectedPanelCount = 1;

  Uint8List? _newImageBytes;
  String? _existingPhotoBase64;
  bool _saving = false;

  bool get _isEditing => widget.window != null;

  @override
  void initState() {
    super.initState();
    final w = widget.window;
    if (w != null) {
      _nameController.text = w.name;
      if (w.widthMm > 0) _widthController.text = '${w.widthMm}';
      if (w.heightMm > 0) _heightController.text = '${w.heightMm}';
      _existingPhotoBase64 = w.photoBase64;
      _selectedPanelCount = w.panelCount;
      if (w.selectedProductId.isNotEmpty) {
        _selectedProduct =
            Product(id: w.selectedProductId, name: w.selectedProductName);
        if (w.selectedProductVariant.isNotEmpty) {
          _selectedVariant = ProductVariant(name: w.selectedProductVariant);
        }
      }
    }
    _widthController.addListener(_onChanged);
    _heightController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
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
    final h = int.tryParse(_heightController.text);
    if (w == null || h == null || w <= 0 || h <= 0 || _selectedProduct == null) {
      return 'Item price: —';
    }
    final area = (w / 1000.0) * (h / 1000.0);
    final rate = _selectedProduct!.pricePerSqm > 0
        ? _selectedProduct!.pricePerSqm
        : QuoteCalculator.defaultWindowRate;
    final price = rate * area;
    return 'Item price: \$${price.toStringAsFixed(2)} (${area.toStringAsFixed(4)} m²)';
  }

  Future<void> _selectProduct() async {
    final selection = await Navigator.push<ProductSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          category: 'window',
          spaceWidthMm: int.tryParse(_widthController.text) ?? 0,
          spaceHeightMm: int.tryParse(_heightController.text) ?? 0,
        ),
      ),
    );
    if (selection != null) {
      setState(() {
        _selectedProduct = selection.product;
        _selectedVariant = selection.variant;
        _selectedPanelCount = selection.panelCount;
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
    final height = int.tryParse(_heightController.text);
    if (height == null || height < _minMm || height > _maxMm) {
      _showAlert('Validation Error',
          'Height must be between $_minMm and $_maxMm mm.');
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
        final w = widget.window!
          ..name = name
          ..widthMm = width
          ..heightMm = height
          ..selectedProductId = _selectedProduct?.id ?? ''
          ..selectedProductName = _selectedProduct?.name ?? ''
          ..selectedProductVariant = _selectedVariant?.name ?? ''
          ..panelCount = _selectedPanelCount
          ..photoBase64 = photoBase64;
        await FirestoreService.shared.updateWindow(w);
      } else {
        await FirestoreService.shared.addWindow(WindowItem(
          roomId: widget.room.id,
          name: name,
          widthMm: width,
          heightMm: height,
          selectedProductId: _selectedProduct?.id ?? '',
          selectedProductName: _selectedProduct?.name ?? '',
          selectedProductVariant: _selectedVariant?.name ?? '',
          panelCount: _selectedPanelCount,
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Window' : 'Add Window')),
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
                    hintText: 'Window name (e.g. Living Room Bay)'),
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
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration:
                          const InputDecoration(hintText: 'Height (mm)'),
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
                child: const Text('Select Window Product'),
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
                    : const Text('Save Window'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


