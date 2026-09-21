/// The barcode symbologies this package can be told to decode.
///
/// This enum is owned by `camera_scanner_kit`, so restricting a scanner to a
/// specific set of formats never requires adding `mobile_scanner` to your own
/// `pubspec.yaml`:
///
/// ```dart
/// import 'package:camera_scanner_kit/camera_scanner_kit.dart';
///
/// final code = await scanBarcode(
///   context,
///   allowedFormats: [ScannerBarcodeFormat.ean13, ScannerBarcodeFormat.code128],
/// );
/// ```
///
/// **An empty allow-list means "accept every format the device supports."**
/// That is the only way to express "all" — there is deliberately no `all`
/// value, because a list containing `all` alongside other entries has no
/// coherent meaning. There is likewise no `unknown` value: it identifies a
/// decode result, never something you can ask the camera to look for.
///
/// Note that `ScannerViewConfig.barcode` additionally intersects whatever is
/// passed here against its built-in 1D retail set, so a 2D format supplied
/// through that constructor is dropped rather than honoured.
enum ScannerBarcodeFormat {
  /// Code 128. A dense, variable-length 1D symbology used widely in logistics.
  code128,

  /// Code 39. An older variable-length 1D symbology, common in automotive
  /// and defence inventory systems.
  code39,

  /// Code 93. A more compact successor to [code39].
  code93,

  /// Codabar. A 1D symbology used by libraries, blood banks and couriers.
  codabar,

  /// Data Matrix. A compact 2D matrix code used for marking small parts.
  dataMatrix,

  /// EAN-13. The 13-digit retail product barcode used outside North America.
  ean13,

  /// EAN-8. The shortened 8-digit variant of [ean13] for small packaging.
  ean8,

  /// Interleaved 2 of 5. A numeric-only, variable-length 1D symbology.
  itf2of5,

  /// Interleaved 2 of 5 with a trailing check digit.
  itf2of5WithChecksum,

  /// ITF-14. The 14-digit shipping-container form of Interleaved 2 of 5.
  itf14,

  /// QR Code. The general-purpose 2D matrix code.
  qrCode,

  /// UPC-A. The 12-digit retail product barcode used in North America.
  upcA,

  /// UPC-E. The zero-suppressed 6-digit variant of [upcA].
  upcE,

  /// PDF417. A stacked 2D symbology used on driving licences and boarding
  /// passes.
  pdf417,

  /// Aztec. A 2D matrix code common on transit and airline tickets.
  aztec,

  /// MaxiCode. The fixed-size 2D code used by UPS package sortation.
  maxiCode,

  /// Micro QR Code. A reduced-footprint variant of [qrCode].
  microQrCode,

  /// GS1 DataBar (RSS-14). Used for fresh-food and coupon labelling.
  dataBar,

  /// GS1 DataBar Expanded (RSS Expanded). Carries additional GS1 data such as
  /// weight or expiry.
  dataBarExpanded,

  /// GS1 DataBar Limited. A narrower DataBar variant for small items.
  dataBarLimited,
}
