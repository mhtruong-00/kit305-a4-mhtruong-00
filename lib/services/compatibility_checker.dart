// Window/floor product compatibility checker, ported from the iOS
// `CompatibilityChecker`. Determines whether a product fits a given space and
// how many panels are required.
import '../models/product.dart';

class CompatibilityResult {
  final bool compatible;
  final int panelCount;
  final String message;

  const CompatibilityResult({
    required this.compatible,
    required this.panelCount,
    required this.message,
  });
}

class CompatibilityChecker {
  CompatibilityChecker._();

  /// Check whether [product] is compatible with a space of the given
  /// dimensions (millimetres; pass 0 if not set).
  static CompatibilityResult check({
    required Product product,
    required int widthMm,
    required int heightMm,
  }) {
    // Floor products are always compatible.
    if (product.category != 'window') {
      return const CompatibilityResult(
          compatible: true, panelCount: 1, message: '');
    }

    if (widthMm <= 0 && heightMm <= 0) {
      return const CompatibilityResult(
          compatible: true, panelCount: 1, message: 'No dimensions set');
    }

    // Height check.
    if (heightMm > 0) {
      if (heightMm < product.minHeight) {
        return CompatibilityResult(
          compatible: false,
          panelCount: 1,
          message: 'Too short: ${heightMm}mm (min ${product.minHeight}mm required)',
        );
      }
      if (heightMm > product.maxHeight) {
        return CompatibilityResult(
          compatible: false,
          panelCount: 1,
          message: 'Too tall: ${heightMm}mm (max ${product.maxHeight}mm allowed)',
        );
      }
    }

    // Width check (try splitting across panels).
    if (widthMm > 0) {
      final maxPanels = product.maxPanelCount < 1 ? 1 : product.maxPanelCount;
      for (var panels = 1; panels <= maxPanels; panels++) {
        final panelWidth = widthMm / panels;
        if (panelWidth >= product.minWidth && panelWidth <= product.maxWidth) {
          final message = panels == 1
              ? 'Single panel — ${widthMm}mm wide'
              : '$panels panels — each ~${panelWidth.round()}mm wide';
          return CompatibilityResult(
              compatible: true, panelCount: panels, message: message);
        }
      }
      // No panel count fits.
      final String failMessage;
      if (widthMm < product.minWidth) {
        failMessage =
            'Too narrow: ${widthMm}mm (min ${product.minWidth}mm per panel)';
      } else if (product.maxPanelCount <= 1) {
        failMessage =
            'Too wide: ${widthMm}mm exceeds ${product.maxWidth}mm (single panel only)';
      } else {
        failMessage =
            'Cannot fit: ${widthMm}mm cannot be split into 1–${product.maxPanelCount} panels each ${product.minWidth}–${product.maxWidth}mm wide';
      }
      return CompatibilityResult(
          compatible: false, panelCount: 1, message: failMessage);
    }

    return const CompatibilityResult(
        compatible: true, panelCount: 1, message: 'No width set');
  }
}

