// Quote calculation, ported from the iOS `QuoteCalculator` / Android
// `QuoteActivity`:
//   * Per-room subtotal
//   * Per-room labour fee ($200) when the room has a measured + included item
//   * Default rates ($50 window, $100 floor) when no product rate is known
//   * Whole-house discount %
import '../models/floor_space.dart';
import '../models/quote_line_item.dart';
import '../models/room.dart';
import '../models/window_item.dart';

/// Per-room quote totals.
class RoomQuote {
  final Room room;
  List<QuoteLineItem> items;
  bool isIncluded;

  RoomQuote({required this.room, required this.items, this.isIncluded = true});

  double get subtotal => items
      .where((i) => i.isIncluded)
      .fold(0.0, (sum, i) => sum + i.itemPrice);

  bool get hasMeasuredIncludedItem =>
      items.any((i) => i.isIncluded && i.areaSqm > 0);

  /// Labour only applies if the room is included AND has a measured item.
  double labour(double roomLabour) =>
      (isIncluded && hasMeasuredIncludedItem) ? roomLabour : 0;

  double roomTotal(double roomLabour) =>
      isIncluded ? subtotal + labour(roomLabour) : 0;
}

class QuoteCalculator {
  QuoteCalculator._();
  static final QuoteCalculator shared = QuoteCalculator._();

  // Pricing defaults — match the Android `QuoteActivity` constants.
  static const double defaultWindowRate = 50.0;
  static const double defaultFloorRate = 100.0;
  static const double roomLabour = 200.0;

  /// Build [RoomQuote] objects ready for the quote screen.
  /// [productRates] maps productId -> pricePerSqm (loaded from the API).
  List<RoomQuote> buildRoomQuotes({
    required List<Room> rooms,
    required Map<String, List<WindowItem>> windowsByRoom,
    required Map<String, List<FloorSpace>> floorsByRoom,
    required Map<String, double> productRates,
  }) {
    return rooms.map((room) {
      final items = <QuoteLineItem>[];

      for (final w in windowsByRoom[room.id] ?? const []) {
        final resolved = _resolveRate(
            w.selectedProductId, productRates, defaultWindowRate);
        items.add(QuoteLineItem(
          id: w.id,
          roomId: room.id,
          roomName: room.name,
          itemType: QuoteItemType.window,
          itemName: w.name,
          productId: w.selectedProductId,
          productName: w.selectedProductName.isEmpty
              ? 'Basic Window'
              : w.selectedProductName,
          variantName: w.selectedProductVariant,
          widthMm: w.widthMm,
          heightOrDepthMm: w.heightMm,
          panelCount: w.panelCount,
          pricePerSqm: resolved.rate,
          isIncluded: true,
          usedDefaultRate: resolved.isDefault,
        ));
      }

      for (final f in floorsByRoom[room.id] ?? const []) {
        final resolved =
            _resolveRate(f.selectedProductId, productRates, defaultFloorRate);
        items.add(QuoteLineItem(
          id: f.id,
          roomId: room.id,
          roomName: room.name,
          itemType: QuoteItemType.floor,
          itemName: f.name,
          productId: f.selectedProductId,
          productName: f.selectedProductName.isEmpty
              ? 'Basic Floor'
              : f.selectedProductName,
          variantName: f.selectedProductVariant,
          widthMm: f.widthMm,
          heightOrDepthMm: f.depthMm,
          panelCount: 1,
          pricePerSqm: resolved.rate,
          isIncluded: true,
          usedDefaultRate: resolved.isDefault,
        ));
      }

      return RoomQuote(room: room, items: items, isIncluded: true);
    }).toList();
  }

  /// Sum of (room subtotals + room labour) for all included rooms.
  double houseSubtotal(List<RoomQuote> roomQuotes) =>
      roomQuotes.fold(0.0, (sum, rq) => sum + rq.roomTotal(roomLabour));

  /// Apply the % discount to the house subtotal.
  double finalTotal(List<RoomQuote> roomQuotes, double discountPercent) {
    final sub = houseSubtotal(roomQuotes);
    final d = discountPercent.clamp(0, 100);
    return sub * (1.0 - d / 100.0);
  }

  double discountAmount(List<RoomQuote> roomQuotes, double discountPercent) {
    final sub = houseSubtotal(roomQuotes);
    final d = discountPercent.clamp(0, 100);
    return sub * (d / 100.0);
  }

  _ResolvedRate _resolveRate(
      String productId, Map<String, double> rates, double defaultRate) {
    if (productId.isEmpty) return _ResolvedRate(defaultRate, true);
    final rate = rates[productId];
    if (rate != null) return _ResolvedRate(rate, false);
    return _ResolvedRate(defaultRate, true);
  }
}

class _ResolvedRate {
  final double rate;
  final bool isDefault;
  _ResolvedRate(this.rate, this.isDefault);
}

