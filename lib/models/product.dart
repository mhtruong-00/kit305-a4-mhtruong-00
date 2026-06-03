// Product + ProductVariant models, loaded from the KIT305 product API.
import 'firestore_coerce.dart';

class ProductVariant {
  final String id;
  final String name;

  const ProductVariant({this.id = '', this.name = ''});
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category; // "window" or "floor"
  final String? imageUrl;
  final double pricePerSqm;
  final List<ProductVariant> variants;
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;
  final int maxPanelCount;

  const Product({
    this.id = '',
    this.name = '',
    this.description = '',
    this.category = '',
    this.imageUrl,
    this.pricePerSqm = 0,
    this.variants = const [],
    this.minWidth = 0,
    this.maxWidth = 9999,
    this.minHeight = 0,
    this.maxHeight = 9999,
    this.maxPanelCount = 1,
  });

  /// Parse a single product from the API JSON object. Returns null if the
  /// object is missing an id or name. Tolerates string/int/double field types
  /// and both snake_case and camelCase keys, matching the iOS `ProductAPI`.
  static Product? fromJson(Map<String, dynamic> dict) {
    final rawId = dict['id'];
    final String id;
    if (rawId is String) {
      id = rawId;
    } else if (rawId is int) {
      id = rawId.toString();
    } else {
      return null;
    }

    final name = dict['name'] as String?;
    if (name == null || name.isEmpty) return null;

    final imageUrl =
        (dict['image_url'] as String?) ?? (dict['imageUrl'] as String?);

    final pricePerSqm =
        coerceDouble(dict['price_per_sqm'] ?? dict['pricePerSqm']);

    final variants = <ProductVariant>[];
    final rawVariants = dict['variants'];
    if (rawVariants is List) {
      for (var i = 0; i < rawVariants.length; i++) {
        final v = rawVariants[i];
        if (v is String) {
          if (v.isNotEmpty) {
            variants.add(ProductVariant(id: '${id}_v$i', name: v));
          }
        } else if (v is Map) {
          final vname =
              (v['name'] as String?) ?? (v['variant'] as String?) ?? '';
          if (vname.isNotEmpty) {
            final vid = (v['id'] as String?) ?? '${id}_v$i';
            variants.add(ProductVariant(id: vid, name: vname));
          }
        }
      }
    }

    return Product(
      id: id,
      name: name,
      description: dict['description'] as String? ?? '',
      category: dict['category'] as String? ?? '',
      imageUrl: imageUrl,
      pricePerSqm: pricePerSqm,
      variants: variants,
      minWidth: coerceInt(dict['min_width'] ?? dict['minWidth'], fallback: 0),
      maxWidth: coerceInt(dict['max_width'] ?? dict['maxWidth'], fallback: 9999),
      minHeight:
          coerceInt(dict['min_height'] ?? dict['minHeight'], fallback: 0),
      maxHeight:
          coerceInt(dict['max_height'] ?? dict['maxHeight'], fallback: 9999),
      maxPanelCount: coerceInt(
          dict['max_panels'] ?? dict['maxPanels'] ?? dict['maxPanelCount'],
          fallback: 1),
    );
  }
}

