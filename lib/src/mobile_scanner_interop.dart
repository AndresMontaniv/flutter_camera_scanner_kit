/// Translations from this package's public enums to the `mobile_scanner`
/// types they are handed to.
///
/// **This library is deliberately not exported from `camera_scanner_kit.dart`.**
/// Keeping the mappers here — rather than as members on the public enums —
/// is what stops `mobile_scanner`'s types from appearing anywhere a consumer
/// can reach. A public getter returning `BarcodeFormat` or `CameraLensType`
/// would put those types back into this package's API contract even though
/// the enums themselves are ours.
///
/// Any future mapping to a third-party type belongs in this file for the
/// same reason.
library;

import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_barcode_format.dart';
import 'scanner_lens_type.dart';

/// Maps [ScannerBarcodeFormat] onto the `mobile_scanner` enum.
extension ScannerBarcodeFormatInterop on ScannerBarcodeFormat {
  /// The `mobile_scanner` format this value corresponds to.
  ///
  /// The switch is exhaustive and has no `default` branch on purpose: adding a
  /// value to [ScannerBarcodeFormat] without mapping it here is a compile
  /// error rather than a format that silently never decodes.
  BarcodeFormat get mobileScannerFormat {
    return switch (this) {
      ScannerBarcodeFormat.code128 => BarcodeFormat.code128,
      ScannerBarcodeFormat.code39 => BarcodeFormat.code39,
      ScannerBarcodeFormat.code93 => BarcodeFormat.code93,
      ScannerBarcodeFormat.codabar => BarcodeFormat.codabar,
      ScannerBarcodeFormat.dataMatrix => BarcodeFormat.dataMatrix,
      ScannerBarcodeFormat.ean13 => BarcodeFormat.ean13,
      ScannerBarcodeFormat.ean8 => BarcodeFormat.ean8,
      ScannerBarcodeFormat.itf2of5 => BarcodeFormat.itf2of5,
      ScannerBarcodeFormat.itf2of5WithChecksum =>
        BarcodeFormat.itf2of5WithChecksum,
      ScannerBarcodeFormat.itf14 => BarcodeFormat.itf14,
      ScannerBarcodeFormat.qrCode => BarcodeFormat.qrCode,
      ScannerBarcodeFormat.upcA => BarcodeFormat.upcA,
      ScannerBarcodeFormat.upcE => BarcodeFormat.upcE,
      ScannerBarcodeFormat.pdf417 => BarcodeFormat.pdf417,
      ScannerBarcodeFormat.aztec => BarcodeFormat.aztec,
      ScannerBarcodeFormat.maxiCode => BarcodeFormat.maxiCode,
      ScannerBarcodeFormat.microQrCode => BarcodeFormat.microQrCode,
      ScannerBarcodeFormat.dataBar => BarcodeFormat.dataBar,
      ScannerBarcodeFormat.dataBarExpanded => BarcodeFormat.dataBarExpanded,
      ScannerBarcodeFormat.dataBarLimited => BarcodeFormat.dataBarLimited,
    };
  }
}

/// Maps [ScannerLensType] onto the `mobile_scanner` enum.
extension ScannerLensTypeInterop on ScannerLensType {
  /// The `mobile_scanner` lens this value corresponds to.
  CameraLensType get mobileScannerLens {
    return switch (this) {
      ScannerLensType.any => CameraLensType.any,
      ScannerLensType.wide => CameraLensType.wide,
      ScannerLensType.normal => CameraLensType.normal,
      ScannerLensType.zoom => CameraLensType.zoom,
    };
  }
}

/// Convenience for the single point where a resolved allow-list is handed to
/// `MobileScannerController`.
extension ScannerBarcodeFormatListInterop on List<ScannerBarcodeFormat> {
  /// This allow-list expressed in `mobile_scanner`'s vocabulary.
  List<BarcodeFormat> get mobileScannerFormats =>
      map((f) => f.mobileScannerFormat).toList();
}
