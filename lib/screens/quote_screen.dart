// Quote screen, ported from the iOS `QuoteViewController`.
// Loads rooms + windows + floors, fetches product rates, builds per-room
// quotes with include toggles, applies a whole-house discount, shows a notes
// banner, and shares the resulting CSV.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/house.dart';
import '../services/csv_exporter.dart';
import '../services/firestore_service.dart';
import '../services/product_api.dart';
import '../services/quote_calculator.dart';
import '../theme/app_theme.dart';

class QuoteScreen extends StatefulWidget {
  final House house;

  const QuoteScreen({super.key, required this.house});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  bool _loading = true;
  bool _usingDefaults = false;
  double _discountPercent = 0;
  List<RoomQuote> _roomQuotes = [];
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await FirestoreService.shared.loadQuoteData(widget.house.id);
    final products = await ProductAPI.shared.fetchProducts();
    final rates = <String, double>{};
    for (final p in products) {
      if (p.id.isNotEmpty) rates[p.id] = p.pricePerSqm;
    }
    final quotes = QuoteCalculator.shared.buildRoomQuotes(
      rooms: data.rooms,
      windowsByRoom: data.windowsByRoom,
      floorsByRoom: data.floorsByRoom,
      productRates: rates,
    );
    if (!mounted) return;
    setState(() {
      _usingDefaults = products.isEmpty;
      _roomQuotes = quotes;
      _loading = false;
    });
  }

  void _applyDiscount(String text) {
    final value = double.tryParse(text.trim()) ?? 0;
    setState(() => _discountPercent = value.clamp(0, 100).toDouble());
  }

  Future<void> _share() async {
    final csv = CSVExporter.shared.generateCSV(
      houseName: widget.house.name,
      address: widget.house.address,
      roomQuotes: _roomQuotes,
      discountPercent: _discountPercent,
      usingDefaults: _usingDefaults,
      notes: widget.house.notes,
    );
    try {
      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safeName = widget.house.name.replaceAll(' ', '_');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/quote_${safeName}_$date.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Quote for ${widget.house.name}',
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: csv,
          subject: 'Quote for ${widget.house.name}',
        ),
      );
    }
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final subtotal = QuoteCalculator.shared.houseSubtotal(_roomQuotes);
    final discountAmt =
        QuoteCalculator.shared.discountAmount(_roomQuotes, _discountPercent);
    final total =
        QuoteCalculator.shared.finalTotal(_roomQuotes, _discountPercent);
    final notes = widget.house.notes.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quote — ${widget.house.name}'),
        actions: [
          IconButton(
            tooltip: 'Share CSV',
            icon: const Icon(Icons.share),
            onPressed: _loading ? null : _share,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (notes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.quoteTint.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📝 Notes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.quoteTint)),
                              const SizedBox(height: 4),
                              Text(notes),
                            ],
                          ),
                        ),
                      if (_roomQuotes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: Text('No rooms in this house yet.')),
                        ),
                      for (var s = 0; s < _roomQuotes.length; s++)
                        _roomSection(s),
                    ],
                  ),
                ),
                _summaryCard(subtotal, discountAmt, total),
              ],
            ),
    );
  }

  Widget _roomSection(int section) {
    final rq = _roomQuotes[section];
    final labour = rq.labour(QuoteCalculator.roomLabour);
    final roomTotal = rq.roomTotal(QuoteCalculator.roomLabour);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Text(rq.room.name.isEmpty ? 'Unnamed Room' : rq.room.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${rq.items.length} item${rq.items.length == 1 ? '' : 's'}'),
            trailing: Switch(
              activeThumbColor: AppColors.quoteTint,
              value: rq.isIncluded,
              onChanged: (v) => setState(() => rq.isIncluded = v),
            ),
          ),
          for (final item in rq.items)
            Opacity(
              opacity: rq.isIncluded ? (item.isIncluded ? 1 : 0.5) : 0.4,
              child: ListTile(
                dense: true,
                title: Text(item.itemName.isEmpty ? 'Unnamed' : item.itemName),
                subtitle: Text(
                    '${item.typeLabel} • ${item.dimensionLabel} • ${item.productName}'
                    '${item.usedDefaultRate ? ' (default rate)' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.priceLabel),
                    Switch(
                      activeThumbColor: AppColors.quoteTint,
                      value: item.isIncluded,
                      onChanged: rq.isIncluded
                          ? (v) => setState(() => item.isIncluded = v)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rq.isIncluded
                      ? 'Items ${_money(rq.subtotal)}  +  Labour ${_money(labour)}'
                      : 'Room excluded from quote',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                Text(
                  rq.isIncluded ? _money(roomTotal) : '—',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rq.isIncluded ? AppColors.quoteTint : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(double subtotal, double discountAmt, double total) {
    final hints = <String>[];
    if (_usingDefaults) {
      hints.add(
          'Using default rates (\$50 window • \$100 floor) — product API unavailable.');
    }
    final excluded = _roomQuotes.where((rq) => !rq.isIncluded).length;
    if (excluded > 0) {
      hints.add('$excluded room${excluded == 1 ? '' : 's'} excluded.');
    }

    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(hints.join('  '),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(_money(subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Discount'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '0'),
                    onChanged: _applyDiscount,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('%'),
                const Spacer(),
                Text(
                  _discountPercent > 0 ? '-${_money(discountAmt)}' : '\$0.00',
                  style: TextStyle(
                    color: _discountPercent > 0
                        ? Colors.orange
                        : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FINAL TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.quoteTint)),
                Text(
                  _money(total),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.quoteTint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


