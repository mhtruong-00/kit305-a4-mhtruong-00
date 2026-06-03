// Fetches products from the KIT305 product API.
//   All:    https://utasbot.dev/kit305_2026/product
//   Window: https://utasbot.dev/kit305_2026/product?category=window
//   Floor:  https://utasbot.dev/kit305_2026/product?category=floor
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductAPI {
  ProductAPI._();
  static final ProductAPI shared = ProductAPI._();

  static const String _baseUrl = 'https://utasbot.dev/kit305_2026/product';

  /// Fetch products, optionally filtered by [category] ("window" / "floor").
  /// Returns an empty list on any network or parse error.
  Future<List<Product>> fetchProducts({String? category}) async {
    final query = (category != null && category.isNotEmpty)
        ? {'category': category}
        : <String, String>{};
    final uri = Uri.parse(_baseUrl).replace(queryParameters: query.isEmpty ? null : query);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // ignore: avoid_print
        print('[ProductAPI] HTTP ${response.statusCode}');
        return [];
      }
      return _parseProducts(response.body);
    } catch (e) {
      // ignore: avoid_print
      print('[ProductAPI] network error: $e');
      return [];
    }
  }

  /// Supports both a bare JSON array and a `{ "data": [...] }` wrapped payload.
  List<Product> _parseProducts(String body) {
    final dynamic raw = jsonDecode(body);
    List<dynamic> array;
    if (raw is List) {
      array = raw;
    } else if (raw is Map && raw['data'] is List) {
      array = raw['data'] as List;
    } else {
      // ignore: avoid_print
      print('[ProductAPI] unexpected JSON shape');
      return [];
    }

    final products = <Product>[];
    for (final item in array) {
      if (item is Map<String, dynamic>) {
        final p = Product.fromJson(item);
        if (p != null) products.add(p);
      } else if (item is Map) {
        final p = Product.fromJson(Map<String, dynamic>.from(item));
        if (p != null) products.add(p);
      }
    }
    return products;
  }
}

