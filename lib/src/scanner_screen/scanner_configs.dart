part of 'scanner_screen.dart';

// MARK: - Constants Values

// ─── Layout Constants ───────────────────────────────────────────────────────
// Default vertical offsets that nudge the scan-window overlay upward from the
// screen center, accounting for visual balance with the toolbar at the top.
const Offset _qrOffset = Offset(0.0, -50.0);
const Offset _barcodeOffset = Offset(0.0, -80.0);

// ─── Barcode Format Allow-List ──────────────────────────────────────────────
/// The canonical set of horizontal 1D barcode symbologies commonly found on
/// retail and warehouse products.  Used as the default format list when the
/// caller selects [ScannerViewConfig.barcode] without specifying a custom
/// subset.  Keeping this explicit (instead of an empty list which means
/// "accept all") prevents the controller from wasting decode cycles on 2D
/// matrix codes when the overlay is clearly a horizontal strip.
const List<BarcodeFormat> _horizontal1DFormats = [
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf14,
  BarcodeFormat.codabar,
];

// MARK: - ToolBar classes

/// Internal routing mode enum — set once by the named constructor and never
/// changed. The `_ScannerScreenState` switches on this to decide how to
/// route scanned data (pop a single value, accumulate a batch, or stream).
enum _ScanMode { single, multiscan }

/// Base class for configuring the overlay toolbar.
sealed class ScannerToolBar {
  /// Padding around the toolbar items inside the overlay.
  final EdgeInsetsGeometry padding;

  /// Alignment of the toolbar relative to the scanner screen overlay bounds.
  /// Defaults to [Alignment.topCenter].
  final AlignmentGeometry alignment;

  /// Creates a [ScannerToolBar] configuration instance.
  const ScannerToolBar({
    this.alignment = Alignment.topCenter,
    this.padding = const EdgeInsets.all(16.0),
  });

  /// Returns `true` if the toolbar contains at least one visible element
  /// that needs to be laid out and rendered.
  bool get shouldBuild;
}

/// A standard toolbar configuration containing action buttons for flash, close,
/// and camera-switching, along with space for custom trailing widgets.
class StandardToolBar extends ScannerToolBar {
  /// Whether to display the toggle flashlight button.
  final bool showFlashButton;

  /// Whether to display the close/back button.
  final bool showCloseButton;

  /// Whether to display the camera toggle/switch button.
  final bool showSwitchCameraButton;

  /// Optional list of widgets to place at the end/trailing side of the toolbar.
  final List<Widget>? trailing;

  /// Callback triggered if an error occurs when executing any action button
  /// operations (e.g., failed to switch camera).
  final void Function(Object error)? onActionButtonError;

  /// Creates a standard toolbar config.
  const StandardToolBar({
    this.showCloseButton = true,
    this.showFlashButton = true,
    this.showSwitchCameraButton = true,
    this.trailing,
    this.onActionButtonError,
    super.alignment,
    super.padding,
  });

  @override
  bool get shouldBuild =>
      showFlashButton || showCloseButton || showSwitchCameraButton;
}

/// An extension of [StandardToolBar] that adds support for batch-scanning workflows,
/// including a button or badge showing the count of scanned items.
class BatchToolBar extends StandardToolBar {
  /// Whether to show the scanned item list button/badge in the toolbar.
  final bool showScannedListButton;

  /// Callback triggered when the scanned list button is pressed.
  /// If provided, this overrides the default bottom-sheet modal launcher.
  final void Function(BuildContext, List<String>)? onShowScannedListPressed;

  /// A custom builder function for rendering the list button widget.
  /// Receives the build context and current list of accumulated barcode values.
  final Widget Function(BuildContext, List<String>)? listButtonBuilder;

  /// Creates a batch toolbar config.
  const BatchToolBar({
    this.showScannedListButton = true,
    this.onShowScannedListPressed,
    this.listButtonBuilder,
    super.showFlashButton,
    super.showCloseButton,
    super.showSwitchCameraButton,
    super.trailing,
    super.onActionButtonError,
    super.alignment,
    super.padding,
  });

  @override
  bool get shouldBuild =>
      showFlashButton ||
      showCloseButton ||
      showSwitchCameraButton ||
      showScannedListButton;

  /// Helper to convert this [BatchToolBar] configuration into a [StandardToolBar]
  /// configuration (stripping batch-specific visual components like list button).
  StandardToolBar toStandard() => StandardToolBar(
    showFlashButton: showFlashButton,
    showCloseButton: showCloseButton,
    showSwitchCameraButton: showSwitchCameraButton,
    trailing: trailing,
    onActionButtonError: onActionButtonError,
    alignment: alignment,
    padding: padding,
  );
}

/// A fully custom toolbar configuration which lets you build the entire toolbar
/// widget hierarchy manually.
class CustomToolBar extends ScannerToolBar {
  /// Builder function providing the active [MobileScannerController] to build
  /// customized controls.
  final Widget Function(BuildContext, MobileScannerController?) toolbarBuilder;

  /// Creates a custom toolbar config.
  const CustomToolBar({
    required this.toolbarBuilder,
    super.alignment,
    super.padding,
  });

  @override
  bool get shouldBuild => true;
}

// MARK: - ScannerView class

// ─── Configuration Object: ScannerViewConfig ────────────────────────────────

/// Determines the visual shape of the scan window overlay.
enum _OverlayMode { custom, qrCode, barcode }

/// **Configuration Object Pattern** — encapsulates all visual and
/// hardware-facing scanner parameters (scan window, overlay style, and
/// allowed barcode formats) into a single object.
///
/// Three named constructors provide opinionated presets:
///
/// * **[ScannerViewConfig.new]** (`.custom()`) — full manual control.  The
///   caller supplies an arbitrary [Rect] scan window and an unrestricted
///   format list.  Use this when the built-in presets don't fit.
///
/// * **[ScannerViewConfig.qrCode]** — optimized for 2D/matrix codes.
///   Renders a responsive **1 : 1 square** overlay and locks
///   [allowedFormats] to `[BarcodeFormat.qrCode]`, eliminating accidental
///   1D reads that would otherwise waste decode cycles.
///
/// * **[ScannerViewConfig.barcode]** — optimized for horizontal 1D
///   product barcodes (EAN-13, UPC-A, Code 128, etc.).  Renders a wide
///   landscape-oriented overlay.  When [allowedFormats] is left empty, the
///   controller defaults to the full [_horizontal1DFormats] set; when a
///   subset is passed, only formats that *also* appear in that allow-list
///   are kept — preventing callers from accidentally enabling 2D codes
///   through this constructor.
class ScannerViewConfig {
  /// Internal overlay shape discriminator set by the chosen constructor.
  final _OverlayMode _mode;

  /// An explicit scan-window rectangle. Only used by the default/custom
  /// constructor; the preset constructors compute their own windows
  /// responsively.
  final Rect? scanWindow;

  /// Vertical/horizontal nudge applied to the preset scan-window position.
  /// Ignored by the custom constructor.
  final Offset? offsetFromCenter;

  /// Optional visual styling for the overlay painter (border color, corner
  /// radius, background dim color, etc.).
  final ScannerOverlayStyle? overlayStyle;

  /// Barcode symbologies the controller will attempt to decode.
  /// An empty list means "accept everything the device supports."
  final List<BarcodeFormat> allowedFormats;

  /// Creates a scanner with a **custom** scan window and format list.
  ///
  /// [scanWindow] lets the caller supply an arbitrary [Rect] for the detection
  /// region. When `null`, no scan-window restriction is applied.
  ///
  /// [allowedFormats] will passed directly to the controller with no filtering.
  /// When empty (the default), all formats supported by the device are
  /// detected.
  const ScannerViewConfig({
    this.scanWindow,
    this.overlayStyle,
    this.allowedFormats = const <BarcodeFormat>[],
  }) : _mode = _OverlayMode.custom,
       offsetFromCenter = null;

  /// Creates a scanner optimized for **QR / 2D matrix codes**.
  ///
  /// The scan window is a responsive 1:1 square.
  const ScannerViewConfig.qrCode({
    this.overlayStyle,
    this.offsetFromCenter,
  }) : _mode = _OverlayMode.qrCode,
       scanWindow = null,
       allowedFormats = const [BarcodeFormat.qrCode];

  /// Creates a scanner optimized for **1D product barcodes**.
  ///
  /// [allowedFormats] defaults to the standard set of store-product 1D
  /// symbologies. The caller may pass a subset to narrow detection further.
  const ScannerViewConfig.barcode({
    this.overlayStyle,
    this.offsetFromCenter,
    this.allowedFormats = const [],
  }) : _mode = _OverlayMode.barcode,
       scanWindow = null;
}
