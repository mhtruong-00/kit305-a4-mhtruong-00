// Product list screen, ported from the iOS `ProductListViewController`.
// Loads products from the KIT305 API filtered by category, shows window
// compatibility, and returns the chosen product/variant/panelCount via
// Navigator.pop.
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/compatibility_checker.dart';
import '../services/product_api.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'product_variant_screen.dart';

/// Result returned to the edit screens when a product is chosen.
class ProductSelection {
  final Product product;
  final ProductVariant? variant;
  final int panelCount;

  ProductSelection(this.product, this.variant, this.panelCount);
}

class ProductListScreen extends StatefulWidget {
  final String category; // "window" or "floor"
  final int spaceWidthMm;
  final int spaceHeightMm;

  const ProductListScreen({
    super.key,
    required this.category,
    this.spaceWidthMm = 0,
    this.spaceHeightMm = 0,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _loading = true;
  List<Product> _products = [];
  String _query = '';

  String get _title {
    switch (widget.category) {
      case 'window':
        return 'Window Products';
      case 'floor':
        return 'Floor Products';
      default:
        return 'Select Product';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products =
        await ProductAPI.shared.fetchProducts(category: widget.category);
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  List<Product> get _displayed {
    if (_query.isEmpty) return _products;
    final q = _query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  CompatibilityResult? _compatFor(Product product) {
    if (product.category != 'window') return null;
    return CompatibilityChecker.check(
      product: product,
      widthMm: widget.spaceWidthMm,
      heightMm: widget.spaceHeightMm,
    );
  }

  Future<void> _select(Product product) async {
    final compat = _compatFor(product);
    if (compat != null && !compat.compatible) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Select'),
          content: Text(compat.message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final panelCount = compat?.panelCount ?? 1;

    if (product.variants.isEmpty) {
      Navigator.pop(context, ProductSelection(product, null, panelCount));
      return;
    }
    final variant = await Navigator.push<ProductVariant>(
      context,
      MaterialPageRoute(
          builder: (_) => ProductVariantScreen(product: product)),
    );
    if (variant != null && mounted) {
      Navigator.pop(context, ProductSelection(product, variant, panelCount));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingIndicator(message: 'Loading products…')
                : _displayed.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(
                              icon: Icons.inventory_2_outlined,
                              message: 'No products found.',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: _displayed.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = _displayed[index];
                            final compat = _compatFor(product);
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.description.isNotEmpty)
                                    Text(product.description),
                                  Text(
                                      '\$${product.pricePerSqm.toStringAsFixed(2)}/m²'),
                                  if (compat != null)
                                    Text(
                                      compat.message,
                                      style: TextStyle(
                                        color: compat.compatible
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: compat != null && !compat.compatible
                                  ? const Icon(Icons.block, color: Colors.red)
                                  : const Icon(Icons.chevron_right),
                              onTap: () => _select(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}






