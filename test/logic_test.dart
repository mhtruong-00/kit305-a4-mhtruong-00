// Unit tests for the pure business logic (no Firebase needed):
// the quote calculator and the product compatibility checker.
import 'package:flutter_test/flutter_test.dart';
import 'package:kit305_a4/models/floor_space.dart';
import 'package:kit305_a4/models/product.dart';
import 'package:kit305_a4/models/room.dart';
import 'package:kit305_a4/models/window_item.dart';
import 'package:kit305_a4/services/compatibility_checker.dart';
import 'package:kit305_a4/services/quote_calculator.dart';

void main() {
  group('QuoteCalculator', () {
    test('window uses product rate and room adds labour', () {
      final room = Room(id: 'r1', houseId: 'h1', name: 'Lounge');
      final window = WindowItem(
        id: 'w1',
        roomId: 'r1',
        name: 'Bay',
        widthMm: 2000,
        heightMm: 1000, // 2.0 m²
        selectedProductId: 'p1',
      );
      final quotes = QuoteCalculator.shared.buildRoomQuotes(
        rooms: [room],
        windowsByRoom: {'r1': [window]},
        floorsByRoom: {},
        productRates: {'p1': 100.0}, // $100/m²
      );
      // 2.0 m² * $100 = $200 items + $200 labour = $400
      expect(quotes.single.subtotal, 200.0);
      expect(QuoteCalculator.shared.houseSubtotal(quotes), 400.0);
    });

    test('default rate applied when product id unknown', () {
      final room = Room(id: 'r1', houseId: 'h1', name: 'Bed');
      final floor = FloorSpace(
        id: 'f1',
        roomId: 'r1',
        widthMm: 1000,
        depthMm: 1000, // 1 m²
      );
      final quotes = QuoteCalculator.shared.buildRoomQuotes(
        rooms: [room],
        windowsByRoom: {},
        floorsByRoom: {'r1': [floor]},
        productRates: {},
      );
      // default floor rate $100 * 1 m² = $100
      expect(quotes.single.items.single.usedDefaultRate, isTrue);
      expect(quotes.single.subtotal, 100.0);
    });

    test('discount reduces the final total', () {
      final room = Room(id: 'r1', houseId: 'h1', name: 'Lounge');
      final window = WindowItem(
        id: 'w1',
        roomId: 'r1',
        widthMm: 1000,
        heightMm: 1000,
        selectedProductId: 'p1',
      );
      final quotes = QuoteCalculator.shared.buildRoomQuotes(
        rooms: [room],
        windowsByRoom: {'r1': [window]},
        floorsByRoom: {},
        productRates: {'p1': 100.0},
      );
      // items $100 + labour $200 = $300; 10% off = $270
      expect(QuoteCalculator.shared.finalTotal(quotes, 10), 270.0);
    });
  });

  group('CompatibilityChecker', () {
    test('floor products are always compatible', () {
      const product = Product(category: 'floor');
      final result =
          CompatibilityChecker.check(product: product, widthMm: 0, heightMm: 0);
      expect(result.compatible, isTrue);
    });

    test('window too tall is rejected', () {
      const product = Product(
        category: 'window',
        minHeight: 100,
        maxHeight: 2000,
        minWidth: 100,
        maxWidth: 2000,
        maxPanelCount: 1,
      );
      final result = CompatibilityChecker.check(
          product: product, widthMm: 500, heightMm: 3000);
      expect(result.compatible, isFalse);
    });

    test('wide window splits across panels', () {
      const product = Product(
        category: 'window',
        minHeight: 100,
        maxHeight: 3000,
        minWidth: 500,
        maxWidth: 1500,
        maxPanelCount: 3,
      );
      final result = CompatibilityChecker.check(
          product: product, widthMm: 3000, heightMm: 1000);
      expect(result.compatible, isTrue);
      expect(result.panelCount, 2); // 3000 / 2 = 1500 ≤ maxWidth
    });
  });
}

