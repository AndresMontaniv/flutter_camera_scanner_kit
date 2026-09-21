/// A production-ready Flutter UI toolkit for barcode and QR scanning.
///
/// Built on `mobile_scanner`, this package offers eleven navigation functions
/// covering single scan, batch accumulation, streaming and a complete POS
/// screen, plus two headless helpers that decode an existing image file with
/// no camera at all. Features hardware-safe tripwires, customizable toolbars,
/// and dynamic overlays for enterprise apps.
library;

export 'src/functions.dart';

// Headless static-image decoding — no BuildContext, no Navigator.
export 'src/image_analysis.dart';

// Inline Scanner Engine
export 'src/inline_scanner/inline_scanner.dart'
    show BarcodeScannerView, BarcodeScannerController;

// Ready-to-use Screens
export 'src/prebuilt_screens/pos_barcode_scanner_screen.dart';

// Public enums owned by this package. The mappers that translate them into
// `mobile_scanner` types live in `src/mobile_scanner_interop.dart`, which is
// deliberately NOT exported — that is what lets an app restrict formats or
// pick a lens without adding `mobile_scanner` to its own `pubspec.yaml`.
//
// One foreign type does still reach the surface: `CustomToolBar.toolbarBuilder`
// hands the raw `MobileScannerController` to its builder. An inline closure
// infers it without the import, but a named builder cannot. Tracked for a
// future major release.
export 'src/scanner_barcode_format.dart';
export 'src/scanner_lens_type.dart';

// The Template Engine
export 'src/scanner_screen/scanner_screen.dart';

// Shared UI
export 'src/widgets/scanner_overlay.dart' show ScannerOverlayStyle;

// Scan-window geometry. Only the shape enum is public; `ScannerView` and the
// layout helpers stay package-internal.
export 'src/widgets/scanner_view.dart' show BarcodeWindowShape;
