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
///   against [horizontal1DFormats] to prevent accidental 2D inclusion.
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
    return allowed.where(horizontal1DFormats.contains).toList();
  }
  return allowed;
}
