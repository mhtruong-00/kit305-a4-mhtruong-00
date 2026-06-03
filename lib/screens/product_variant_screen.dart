// Product variant picker, ported from the iOS `ProductVariantViewController`.
import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductVariantScreen extends StatelessWidget {
  final Product product;

  const ProductVariantScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Select a Variant',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final variant in product.variants)
            ListTile(
              title: Text(variant.name),
              onTap: () => Navigator.pop(context, variant),
            ),
        ],
      ),
    );
  }
}

