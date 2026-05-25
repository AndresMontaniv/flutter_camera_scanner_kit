/// A production-ready Flutter UI toolkit for barcode and QR scanning.
///
/// Built on `mobile_scanner`, this package offers 9 routing modes including
/// single scan, batch accumulation, and a complete POS screen. Features
/// hardware-safe tripwires, customizable toolbars, and dynamic overlays
/// for enterprise apps.
library;

// scanner_screen.dart already includes scanner_configs.dart and
// scanner_top_bar.dart via `part` directives.
export 'src/scanner_screen.dart';
export 'src/pos_barcode_scanner_screen.dart';
export 'src/functions.dart';

// Expose only the public styling class; the internal overlay widget
// and painter remain hidden.
export 'src/scanner_overlay.dart' show ScannerOverlayStyle;

// Inline scanner module: embeddable scanner view with controller architecture.
export 'src/inline_scanner/inline_scanner.dart' show BarcodeScannerView, BarcodeScannerController;
