import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_overlay.dart';

part 'scanner_error_widget.dart';

/// The vertical proportion of the **1D barcode** scan window.
///
/// This controls the *height* of the rectangle and nothing else.  Detection
/// stays locked to the standard horizontal 1D retail symbologies in every
/// case — this is a viewport shape, not a scan mode.  In particular,
/// [BarcodeWindowShape.square] renders a square *window* that still refuses
/// QR and other 2D codes.
///
/// The window's **width** is identical for all three values: 85 % of the
/// device's shortest side, clamped to 250–400 logical pixels.
enum BarcodeWindowShape {
  /// The classic narrow strip — a fixed 130 lp height.
  ///
  /// This is the default and reproduces the historic 1.2.0 geometry exactly.
  standard,

  /// A taller window whose height is 60 % of the responsive width.
  ///
  /// A middle ground for users who struggle to align a barcode inside the
  /// narrow [standard] strip.
  tall,

  /// A responsive 1:1 square — height equals the responsive width.
  ///
  /// The most forgiving target for poorly aligned or angled 1D barcodes.
  square,
}

/// A highly optimized, boilerplate-free wrapper around [MobileScanner] that
/// handles responsive overlays, error states, and app lifecycle management
/// automatically.
///
/// [ScannerView] uses a [Stack] internally so consumers can layer
/// arbitrary widgets (toolbars, guides, flash toggles) on top of the live
/// camera feed without managing the underlying [MobileScanner] plumbing.
///
/// Three constructors are provided for common use-cases:
///
/// * [ScannerView.new] — fully custom, unopinionated scanner layout.
/// * [ScannerView.qrCode] — responsive 1:1 square scan window for 2D
///   matrix codes.
/// * [ScannerView.barcode] — responsive horizontal scan window for 1D
///   barcodes.
class ScannerView extends StatelessWidget {
  /// The [BoxFit] strategy used by the camera preview.
  ///
  /// Defaults to [BoxFit.cover] so the camera feed fills the entire screen
  /// without letterboxing.
  final BoxFit fit;

  /// An optional pixel offset applied to the scan window's center.
  ///
  /// Positive `dy` values push the window downward, which is useful for
  /// accommodating a top app bar or status-bar inset.
  final Offset? offsetFromCenter;

  /// Whether the camera should refocus when the user taps on the preview.
  ///
  /// Defaults to `false`.
  final bool tapToFocus;

  /// A manually specified scan window rectangle in logical pixels.
  ///
  /// ⚠️ BEST PRACTICE: Use the [ScannerView.qrCode] or
  /// [ScannerView.barcode] constructors instead of hardcoding this value
  /// for truly responsive layouts.
  final Rect? scanWindow;

  /// Whether to automatically render the default [ScannerOverlay] around the
  /// computed [scanWindow].
  ///
  /// Defaults to `true` in the [ScannerView.qrCode] and
  /// [ScannerView.barcode] constructors to mimic `mobile_scanner`
  /// behavior, and to `false` in the default constructor.
  final bool autoDrawOverlay;

  /// Whether [MobileScanner] should automatically pause and resume the camera
  /// when the app goes to the background and foreground.
  ///
  /// Defaults to `true`.
  final bool useAppLifecycleState;

  /// Additional widgets layered on top of the camera preview inside the
  /// internal [Stack].
  ///
  /// Use this to add toolbars, scan-line animations, instructional text, or
  /// any other overlay without rebuilding the scanner.
  final List<Widget> stackChildren;

  /// The minimum size change (in logical pixels) required before the
  /// [MobileScanner] recalculates the scan window.
  ///
  /// Defaults to `0.0`, meaning every layout change triggers an update.
  final double scanWindowUpdateThreshold;

  /// An optional style applied to the default [ScannerOverlay].
  ///
  /// Only takes effect when [autoDrawOverlay] is `true`.
  final ScannerOverlayStyle? overlayStyle;

  /// An optional external [MobileScannerController].
  ///
  /// When `null`, [MobileScanner] creates and manages its own controller
  /// internally.
  final MobileScannerController? controller;

  /// Called every time one or more barcodes are detected within the
  /// [scanWindow].
  final void Function(BarcodeCapture)? onDetect;

  /// A builder that provides a placeholder widget displayed while the camera
  /// hardware is initializing.
  ///
  /// When `null`, a default black screen with a subtle white spinner is shown
  /// to prevent a jarring flash during the 300 ms–800 ms initialization phase.
  final Widget Function(BuildContext)? placeholderBuilder;

  /// A builder that provides a fully custom overlay widget drawn on top of the
  /// camera preview.
  ///
  /// When provided, this takes precedence over [autoDrawOverlay] and
  /// [overlayStyle].
  final Widget Function(BuildContext, BoxConstraints)? overlayBuilder;

  /// A builder that provides a custom error widget when the scanner encounters
  /// a [MobileScannerException].
  ///
  /// When `null`, a default black screen with a white error icon and message
  /// is displayed.
  final Widget Function(BuildContext, MobileScannerException)? errorBuilder;

  /// The vertical proportion of the scan window.
  ///
  /// Only honoured by [ScannerView.barcode]; the other constructors pin it to
  /// [BarcodeWindowShape.standard] and ignore it.
  final BarcodeWindowShape windowShape;

  /// Internal function reference used by named constructors to calculate a
  /// responsive scan window at build time.
  ///
  /// The shape travels through this signature rather than through a captured
  /// closure because the field is assigned from `const` constructors, which
  /// cannot allocate closures.
  final Rect Function(
    BuildContext, {
    Offset? offsetFromCenter,
    BarcodeWindowShape windowShape,
  })?
  _calculateScanWindow;

  /// Creates a fully custom, unopinionated scanner layout.
  ///
  /// No scan window is calculated automatically and no overlay is drawn.
  /// Use this constructor when you need complete control over the scan region
  /// and visual presentation.
  const ScannerView({
    super.key,
    this.onDetect,
    this.controller,
    this.scanWindow,
    this.errorBuilder,
    this.overlayStyle,
    this.overlayBuilder,
    this.placeholderBuilder,
    this.fit = BoxFit.cover,
    this.tapToFocus = false,
    this.autoDrawOverlay = false,
    this.useAppLifecycleState = true,
    this.scanWindowUpdateThreshold = 0.0,
    this.stackChildren = const <Widget>[],
  }) : _calculateScanWindow = null,
       windowShape = BarcodeWindowShape.standard,
       offsetFromCenter = Offset.zero;

  /// Creates a scanner with an automatically calculated, responsive **1:1
  /// square** scan window optimized for 2D matrix codes (QR, Data Matrix,
  /// Aztec, etc.).
  ///
  /// The scan window size is derived from the device's shortest side and
  /// clamped to sane min/max bounds so it looks correct on phones and tablets
  /// alike. An overlay is drawn by default.
  const ScannerView.qrCode({
    super.key,
    this.onDetect,
    this.controller,
    this.errorBuilder,
    this.offsetFromCenter,
    this.overlayStyle,
    this.placeholderBuilder,
    this.fit = BoxFit.cover,
    this.tapToFocus = false,
    this.useAppLifecycleState = true,
    this.scanWindowUpdateThreshold = 0.0,
    this.stackChildren = const <Widget>[],
  }) : scanWindow = null,
       overlayBuilder = null,
       autoDrawOverlay = true,
       windowShape = BarcodeWindowShape.standard,
       _calculateScanWindow = _calculateQrCodeScanWindow;

  /// Creates a scanner with an automatically calculated, responsive
  /// **horizontal rectangle** scan window optimized for 1D barcodes (EAN-13,
  /// Code 128, UPC-A, etc.).
  ///
  /// The scan window width is derived from the device's shortest side and
  /// clamped to sane min/max bounds.  Its height follows [windowShape], which
  /// defaults to the fixed, narrow [BarcodeWindowShape.standard] strip that
  /// encourages the user to align the barcode horizontally. An overlay is
  /// drawn by default.
  const ScannerView.barcode({
    super.key,
    this.onDetect,
    this.controller,
    this.errorBuilder,
    this.offsetFromCenter,
    this.overlayStyle,
    this.placeholderBuilder,
    this.fit = BoxFit.cover,
    this.tapToFocus = false,
    this.useAppLifecycleState = true,
    this.scanWindowUpdateThreshold = 0.0,
    this.stackChildren = const <Widget>[],
    this.windowShape = BarcodeWindowShape.standard,
  }) : scanWindow = null,
       overlayBuilder = null,
       autoDrawOverlay = true,
       _calculateScanWindow = _calculateBarcodeScanWindow;

  @override
  Widget build(BuildContext context) {
    final overlayRect =
        _calculateScanWindow?.call(
          context,
          offsetFromCenter: offsetFromCenter,
          windowShape: windowShape,
        ) ??
        scanWindow;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            fit: fit,
            onDetect: onDetect,
            tapToFocus: tapToFocus,
            controller: controller,
            scanWindow: overlayRect,
            useAppLifecycleState: useAppLifecycleState,
            scanWindowUpdateThreshold: scanWindowUpdateThreshold,
            placeholderBuilder:
                placeholderBuilder ?? (_) => const _DefaultScannerPlaceholder(),
            errorBuilder:
                errorBuilder ?? (_, error) => _ScannerErrorWidget(error: error),
            overlayBuilder:
                overlayBuilder ??
                (overlayRect == null || !autoDrawOverlay
                    ? null
                    : (_, constraints) => ScannerOverlay(
                        style: overlayStyle,
                        scanWindow: overlayRect,
                        constraints: constraints,
                      )),
          ),
          ...stackChildren,
        ],
      ),
    );
  }
}

// ==========================================
// PRIVATE LAYOUT HELPERS (Invisible to package users)
// ==========================================

// Layout constants are isolated here as top-level privates so they never
// pollute the public API surface of the package.

// QR code scan window sizing.
// The window is a 1:1 square whose side length equals 70 % of the device's
// shortest side, clamped between 200 lp and 350 lp.
const double _qrSizeRatio = 0.70;
const double _qrMinSize = 200.0;
const double _qrMaxSize = 350.0;

// Barcode scan window sizing.
// The window width equals 85 % of the shortest side, clamped between 250 lp
// and 400 lp. Height depends on the requested [BarcodeWindowShape]:
// `standard` keeps the historic fixed 130 lp strip, while `tall` and `square`
// derive their height from that responsive width.
const double _barcodeWidthRatio = 0.85;
const double _barcodeMinWidth = 250.0;
const double _barcodeMaxWidth = 400.0;
const double _barcodeHeight = 130.0;
const double _barcodeTallRatio = 0.60;

/// Vertical space reserved at the top of the screen for the scanner toolbar.
///
/// `StandardToolBar` sits inside a `SafeArea` with 16 lp of padding around a
/// 28 lp icon button; this adds a small margin on top of that so a scan window
/// never crowds the flash/close controls.
///
/// Library-internal: `scanner_view.dart` is not exported from the package
/// barrel, so this is invisible to consumers despite the missing underscore.
/// It is shared with `pos_barcode_scanner_screen.dart`.
const double kToolbarClearance = 72.0;

// Margin kept between a scan window and the bottom inset.
const double _barcodeBottomClearance = 12.0;

/// Resolves the responsive size of a 1D barcode scan window.
///
/// Width is always 85 % of [screenSize]'s shortest side clamped to
/// `[250, 400]`; only the height varies with [shape].
///
/// Pure by design so the geometry can be unit-tested without a `BuildContext`.
/// Library-internal — see [kToolbarClearance].
Size barcodeWindowSize(Size screenSize, BarcodeWindowShape shape) {
  final double baseWidth = screenSize.shortestSide * _barcodeWidthRatio;
  final double width = baseWidth.clamp(_barcodeMinWidth, _barcodeMaxWidth);

  final double height = switch (shape) {
    BarcodeWindowShape.standard => _barcodeHeight,
    BarcodeWindowShape.tall => width * _barcodeTallRatio,
    BarcodeWindowShape.square => width,
  };

  return Size(width, height);
}

/// Computes the 1D barcode scan window rectangle.
///
/// For [BarcodeWindowShape.standard] this is exactly the 1.2.0 formula —
/// a plain `Rect.fromCenter` with no fitting — so existing callers are
/// guaranteed a byte-identical rect.
///
/// For the taller shapes an additional **vertical fit** runs: the window is
/// nudged back inside the band between the toolbar and the bottom inset, and
/// shrunk if that band is shorter than the requested height. Without this a
/// square window would overlap the toolbar on shorter devices.
///
/// Pure by design so the geometry can be unit-tested without a `BuildContext`.
/// Library-internal — see [kToolbarClearance].
Rect barcodeScanWindow(
  Size screenSize,
  EdgeInsets viewPadding,
  Offset? offsetFromCenter,
  BarcodeWindowShape shape,
) {
  final Size windowSize = barcodeWindowSize(screenSize, shape);
  final Offset center = screenSize.center(offsetFromCenter ?? Offset.zero);

  if (shape == BarcodeWindowShape.standard) {
    // Historic path, deliberately untouched.
    return Rect.fromCenter(
      center: center,
      width: windowSize.width,
      height: windowSize.height,
    );
  }

  final double bandTop = viewPadding.top + kToolbarClearance;
  final double bandBottom =
      screenSize.height - viewPadding.bottom - _barcodeBottomClearance;
  final double band = bandBottom - bandTop;

  // A window taller than the available band is shrunk rather than clipped.
  final double height = band <= 0.0
      ? windowSize.height
      : windowSize.height.clamp(0.0, band);
  final double halfHeight = height / 2;

  double centerY = center.dy;
  if (centerY - halfHeight < bandTop) centerY = bandTop + halfHeight;
  if (centerY + halfHeight > bandBottom) centerY = bandBottom - halfHeight;

  return Rect.fromCenter(
    center: Offset(center.dx, centerY),
    width: windowSize.width,
    height: height,
  );
}

// Calculates a responsive 1:1 square scan window for QR / 2D codes.
// The base size is derived from the shortest screen dimension so the window
// scales proportionally across phones and tablets, and then clamped to
// [_qrMinSize, _qrMaxSize] to prevent it from becoming too small on compact
// devices or unnecessarily large on tablets.
Rect _calculateQrCodeScanWindow(
  BuildContext context, {
  Offset? offsetFromCenter,
  // Accepted to satisfy the shared `_calculateScanWindow` signature; the QR
  // window is always a 1:1 square, so the shape is meaningless here.
  BarcodeWindowShape windowShape = BarcodeWindowShape.standard,
}) {
  final offset = offsetFromCenter ?? Offset.zero;
  final screenSize = MediaQuery.sizeOf(context);
  final double baseSize = screenSize.shortestSide * _qrSizeRatio;
  final double scanSize = baseSize.clamp(_qrMinSize, _qrMaxSize);

  return Rect.fromCenter(
    center: screenSize.center(offset),
    width: scanSize,
    height: scanSize,
  );
}

// Calculates a responsive rectangle scan window for 1D barcodes.
//
// A thin MediaQuery wrapper over [barcodeScanWindow]; all the arithmetic lives
// in that pure function so it can be unit-tested directly.
Rect _calculateBarcodeScanWindow(
  BuildContext context, {
  Offset? offsetFromCenter,
  BarcodeWindowShape windowShape = BarcodeWindowShape.standard,
}) {
  return barcodeScanWindow(
    MediaQuery.sizeOf(context),
    MediaQuery.viewPaddingOf(context),
    offsetFromCenter,
    windowShape,
  );
}

// ==========================================
// PRIVATE UI HELPERS
// ==========================================

// Default placeholder shown while the camera hardware initializes.
// Displays a black screen with a subtle white spinner to prevent the jarring
// black-frame flash that occurs during the 300 ms–800 ms hardware
// initialization phase on most devices.
class _DefaultScannerPlaceholder extends StatelessWidget {
  const _DefaultScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Match the typical camera background
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white54, // Subtle white spinner so it isn't blinding
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}
