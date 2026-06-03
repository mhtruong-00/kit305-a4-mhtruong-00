// Quote-line model, ported from the iOS `QuoteLineItem`.
// Pricing comes from a product-rate map (from the API) with sensible defaults.
enum QuoteItemType { window, floor }

class QuoteLineItem {
  final String id;
  final String roomId;
  final String roomName;
  final QuoteItemType itemType;
  final String itemName;
  final String productId;
  final String productName;
  final String variantName;
  final int widthMm;
  final int heightOrDepthMm;
  final int panelCount;
  final double pricePerSqm;
  bool isIncluded;

  /// True when no product was selected OR the API returned no rate, so a
  /// default fallback rate was applied.
  final bool usedDefaultRate;

  QuoteLineItem({
    this.id = '',
    this.roomId = '',
    this.roomName = '',
    this.itemType = QuoteItemType.window,
    this.itemName = '',
    this.productId = '',
    this.productName = '',
    this.variantName = '',
    this.widthMm = 0,
    this.heightOrDepthMm = 0,
    this.panelCount = 1,
    this.pricePerSqm = 0,
    this.isIncluded = true,
    this.usedDefaultRate = false,
  });

  double get areaSqm => (widthMm / 1000.0) * (heightOrDepthMm / 1000.0);

  double get itemPrice => pricePerSqm * areaSqm;

  String get typeLabel => itemType == QuoteItemType.window ? 'Window' : 'Floor';

  String get dimensionLabel {
    final suffix = itemType == QuoteItemType.window ? 'H' : 'D';
    return '${widthMm}W × $heightOrDepthMm$suffix mm';
  }

  String get priceLabel => '\$${itemPrice.toStringAsFixed(2)}';
}

