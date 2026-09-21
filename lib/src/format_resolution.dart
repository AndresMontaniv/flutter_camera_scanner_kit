import 'scanner_barcode_format.dart';

/// The canonical set of horizontal 1D barcode symbologies commonly found on
/// retail and warehouse products.  Used as the default format list when the
/// caller selects `ScannerViewConfig.barcode` without specifying a custom
/// subset.  Keeping this explicit (instead of an empty list which means
/// "accept all") prevents the controller from wasting decode cycles on 2D
/// matrix codes when the overlay is clearly a horizontal strip.
const List<ScannerBarcodeFormat> horizontal1DFormats = [
  ScannerBarcodeFormat.code128,
  ScannerBarcodeFormat.code39,
  ScannerBarcodeFormat.code93,
  ScannerBarcodeFormat.ean13,
  ScannerBarcodeFormat.ean8,
  ScannerBarcodeFormat.upcA,
  ScannerBarcodeFormat.upcE,
  ScannerBarcodeFormat.itf14,
  ScannerBarcodeFormat.codabar,
];

/// Resolves the effective barcode format list for the controller.
///
/// * **[restrictTo1D] with an empty [allowed] list:** returns
///   [horizontal1DFormats].
/// * **[restrictTo1D] with a caller-supplied subset:** intersects the subset
///   against [horizontal1DFormats] to prevent accidental 2D inclusion.  If
///   nothing survives that intersection — the caller asked a 1D overlay for
///   2D-only formats — the full [horizontal1DFormats] set is returned rather
///   than the empty intersection.  An empty list reaches
///   `MobileScannerController` as "detect every supported format", so
///   returning it here would widen the scanner to *all* symbologies, which is
///   the exact opposite of what the caller asked for.
/// * **Otherwise:** passes [allowed] through unchanged.
///
/// Lives here rather than inside `_ScannerScreenState` so the filtering rules
/// can be unit-tested without pumping a camera widget.
List<ScannerBarcodeFormat> resolveEffectiveFormats({
  required List<ScannerBarcodeFormat> allowed,
  required bool restrictTo1D,
}) {
  if (restrictTo1D) {
    if (allowed.isEmpty) {
      return horizontal1DFormats;
    }
    final intersection = allowed.where(horizontal1DFormats.contains).toList();
    // Never hand an empty list downstream — see the dartdoc above.
    return intersection.isEmpty ? horizontal1DFormats : intersection;
  }
  return allowed;
}
