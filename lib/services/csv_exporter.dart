// CSV output mirroring the iOS / Android share format, ported from the iOS
// `CSVExporter`.
import '../models/quote_line_item.dart';
import 'quote_calculator.dart';

class CSVExporter {
  CSVExporter._();
  static final CSVExporter shared = CSVExporter._();

  String generateCSV({
    required String houseName,
    required String address,
    required List<RoomQuote> roomQuotes,
    required double discountPercent,
    required bool usingDefaults,
    String notes = '',
  }) {
    final rows = <String>[];
    rows.add(_csvRow([
      'type', 'house', 'address', 'room',
      'item_type', 'item_name',
      'width_mm', 'height_or_depth_mm',
      'product', 'variant',
      'rate_per_sqm', 'area_sqm', 'item_cost',
      'room_subtotal', 'room_labour', 'room_total', 'included',
    ]));

    for (final rq in roomQuotes) {
      for (final item in rq.items) {
        final includeItem = rq.isIncluded && item.isIncluded;
        final cost = includeItem ? item.itemPrice : 0.0;
        rows.add(_csvRow([
          'item',
          houseName, address,
          rq.room.name.isEmpty ? 'Unnamed Room' : rq.room.name,
          item.itemType == QuoteItemType.window ? 'window' : 'floor',
          item.itemName.isEmpty ? 'Unnamed' : item.itemName,
          '${item.widthMm}', '${item.heightOrDepthMm}',
          item.productName, item.variantName,
          _money(item.pricePerSqm), _area(item.areaSqm), _money(cost),
          '', '', '',
          includeItem ? 'true' : 'false',
        ]));
      }
      final labour = rq.labour(QuoteCalculator.roomLabour);
      final total = rq.roomTotal(QuoteCalculator.roomLabour);
      rows.add(_csvRow([
        'room_total',
        houseName, address,
        rq.room.name.isEmpty ? 'Unnamed Room' : rq.room.name,
        '', '', '', '', '', '', '', '',
        _money(rq.subtotal), _money(labour), _money(total),
        rq.isIncluded ? 'true' : 'false',
      ]));
    }

    final houseSubtotal = QuoteCalculator.shared.houseSubtotal(roomQuotes);
    final discountAmt =
        QuoteCalculator.shared.discountAmount(roomQuotes, discountPercent);
    final finalTotal =
        QuoteCalculator.shared.finalTotal(roomQuotes, discountPercent);

    rows.add(_csvRow(['summary', houseName, address, ...List.filled(14, '')]));
    rows.add(_csvRow(['subtotal', houseName, address, '', '', '', '', '', '', '', '', '', _money(houseSubtotal), '', '', '', '']));
    rows.add(_csvRow(['discount', houseName, address, '', '', '', '', '', '', '', '', '', _money(discountAmt), '', '', '', _percent(discountPercent)]));
    rows.add(_csvRow(['final_total', houseName, address, '', '', '', '', '', '', '', '', '', _money(finalTotal), '', '', '', '']));

    if (usingDefaults) {
      rows.add(_csvRow(['note', houseName, address, '', '', '', '', '', 'Using default product rates', '', '', '', '', '', '', '', '']));
    }
    final trimmedNotes = notes.trim();
    if (trimmedNotes.isNotEmpty) {
      rows.add(_csvRow(['notes', houseName, address, '', '', '', '', '', trimmedNotes, '', '', '', '', '', '', '', '']));
    }

    return rows.join('\n');
  }

  String _csvRow(List<String> values) => values.map(_escape).join(',');

  String _escape(String v) {
    final escaped = v.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  String _money(double v) => v.toStringAsFixed(2);
  String _area(double v) => v.toStringAsFixed(2);
  String _percent(double v) => v.toStringAsFixed(1);
}

