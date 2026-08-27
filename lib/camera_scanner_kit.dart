/// A production-ready Flutter UI toolkit for barcode and QR scanning.
///
/// Built on `mobile_scanner`, this package offers 9 routing modes including
/// single scan, batch accumulation, and a complete POS screen. Features
/// hardware-safe tripwires, customizable toolbars, and dynamic overlays
/// for enterprise apps.
library;

export 'src/functions.dart';

// Inline Scanner Engine
export 'src/inline_scanner/inline_scanner.dart'
    show BarcodeScannerView, BarcodeScannerController;

// Ready-to-use Screens
export 'src/prebuilt_screens/pos_barcode_scanner_screen.dart';

export 'src/scanner_lens_type.dart';

// The Template Engine
export 'src/scanner_screen/scanner_screen.dart';

// Shared UI
export 'src/widgets/scanner_overlay.dart' show ScannerOverlayStyle;
