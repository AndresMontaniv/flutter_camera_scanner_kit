/// Facade API for the [ScannerScreen] widget.
///
/// This file provides the primary public API surface of the `camera_scanner_kit`
/// package.  It abstracts away internal configuration objects and exposes ten
/// clean, purpose-built functions covering every combination of:
///
/// | Routing Mode | Custom | Barcode | QR Code | POS |
/// |---|---|---|---|---|
/// | **Single** | [scanCustom] | [scanBarcode] | [scanQrCode] | — |
/// | **Batch** | [scanCustomBatch] | [scanBarcodeBatch] | [scanQrCodeBatch] | — |
/// | **Stream** | [scanCustomStream] | [scanBarcodeStream] | [scanQrCodeStream] | — |
/// | **POS** | — | [showPosBarcodeScanner] | — | ✓ |
///
/// All functions push a full-screen [ScannerScreen] (or [PosBarcodeScannerScreen])
/// via `Navigator.push` and manage the camera hardware lifecycle automatically.
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '_constants.dart';
import 'pos_barcode_scanner_screen.dart';
import 'scanner_lens_type.dart';
import 'scanner_overlay.dart';
import 'scanner_screen.dart';


// MARK: - Single-Scan

/// Opens the scanner for a **single** scan with a fully custom overlay.
///
/// This is the lowest-level single-scan entry point. It pushes a full-screen
/// [ScannerScreen.singleScan] and returns the first successfully decoded
/// barcode value as a `String?`. Returns `null` if the user dismisses the
/// scanner without scanning.
///
/// The camera hardware is locked **immediately** after the first successful
/// read to prevent ghost scans during the exit animation.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [stackChildren] — Additional widgets layered on top of the camera
///   preview (e.g., instructional banners or brand logos).
/// * [toolBar] — Toolbar configuration. Pass `null` to hide the toolbar.
///   Must **not** be a [BatchToolBar]; use [scanCustomBatch] for batch modes.
/// * [onScanRejected] — Called when a scan is silently rejected (e.g., when
///   [ScannerScreen.allowDuplicates] is `false` and a duplicate is detected).
/// * [scannerViewConfig] — Full manual control over the overlay shape,
///   scan window [Rect], and allowed barcode formats.
/// * [enableSoundAndVibration] — Whether to trigger haptic feedback and an
///   audible beep on a successful scan. Defaults to `true`.
/// * [useDarkModeButtonTheme] — When `true`, toolbar buttons use a dark
///   translucent background. Defaults to `true`.
/// * [lensType] — The physical camera lens to activate. Defaults to
///   [ScannerLensType.any] for maximum device compatibility. See
///   [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — The initial zoom scale for the camera (0.0 – 1.0).
///   Only supported on iOS, macOS, and Android. Pass `null` (default) for
///   no initial zoom.
///
/// ### Example
/// ```dart
/// final barcode = await scanCustom(
///   context,
///   scannerViewConfig: ScannerViewConfig(
///     scanWindow: Rect.fromLTWH(50, 100, 200, 200),
///   ),
///   lensType: ScannerLensType.wide,
///   initialZoom: 0.3,
/// );
///
/// if (barcode != null) {
///   print('Scanned: $barcode');
/// }
/// ```
///
/// ### Errors
/// All exceptions from the camera pipeline are caught internally and logged
/// via [debugPrint]. In the event of a camera error, the function returns
/// `null` rather than throwing.
Future<String?> scanCustom(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Pass `null` to hide the toolbar.
  ScannerToolBar? toolBar,

  /// Called when a scan is silently rejected.
  void Function(String)? onScanRejected,

  /// Full manual control over the overlay shape and allowed formats.
  ScannerViewConfig? scannerViewConfig,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  try {
    final String? scannedItem = await Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder: (_) => ScannerScreen.singleScan(
              toolBar: toolBar,
              stackChildren: stackChildren,
              onScanRejected: onScanRejected,
              scannerViewConfig: scannerViewConfig,
              enableSoundAndVibration: enableSoundAndVibration,
              useDarkModeButtonTheme: useDarkModeButtonTheme,
              lensType: lensType,
              initialZoom: initialZoom,
            ),
          ),
        );

    if (scannedItem != null) {
      debugPrint('$kTag Successfully scanned: $scannedItem');
    }

    return scannedItem;
  } catch (e, stackTrace) {
    debugPrint('$kTag Error on scanning: $e\n$stackTrace');
    return null;
  }
}

/// Opens the scanner for a **single** scan optimized for **horizontal 1D barcodes**.
///
/// Pushes a full-screen [ScannerScreen.singleScan] with a wide, landscape-
/// oriented overlay. Locks the camera hardware immediately after the first
/// successful read and returns the scanned value as a `String?`. Returns
/// `null` if canceled.
///
/// When [allowedFormats] is empty (the default), the scanner restricts
/// detection to the standard set of horizontal 1D symbologies (EAN-13,
/// UPC-A, Code 128, etc.) to avoid wasting decode cycles on 2D matrix codes.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [stackChildren] — Additional widgets layered on top of the camera preview.
/// * [onScanRejected] — Called when a scan is silently rejected.
/// * [overlayStyle] — Visual customization for the overlay border, corner
///   radius, and background dimming. See [ScannerOverlayStyle].
/// * [offsetFromCenter] — Vertical/horizontal nudge applied to the scan
///   window position relative to the screen center.
/// * [toolBar] — Toolbar config. Defaults to a [StandardToolBar].
/// * [allowedFormats] — Restricts detection to specific [BarcodeFormat]s.
///   Values are intersected with the built-in 1D set.
/// * [enableSoundAndVibration] — Haptic and audio feedback on success.
///   Defaults to `true`.
/// * [useDarkModeButtonTheme] — Dark translucent button backgrounds.
///   Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null` (no zoom).
///
/// ### Example
/// ```dart
/// final barcode = await scanBarcode(
///   context,
///   allowedFormats: [BarcodeFormat.ean13, BarcodeFormat.code128],
/// );
/// ```
Future<String?> scanBarcode(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Called when a scan is silently rejected.
  void Function(String)? onScanRejected,

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset? offsetFromCenter,

  /// Toolbar configuration. Defaults to a [StandardToolBar].
  ScannerToolBar? toolBar = const StandardToolBar(),

  /// Restricts detection to specific [BarcodeFormat]s.
  List<BarcodeFormat> allowedFormats = const [],

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  return scanCustom(
    context,
    toolBar: toolBar,
    stackChildren: stackChildren,
    onScanRejected: onScanRejected,
    scannerViewConfig: ScannerViewConfig.barcode(
      overlayStyle: overlayStyle,
      offsetFromCenter: offsetFromCenter,
      allowedFormats: allowedFormats,
    ),
    enableSoundAndVibration: enableSoundAndVibration,
    useDarkModeButtonTheme: useDarkModeButtonTheme,
    lensType: lensType,
    initialZoom: initialZoom,
  );
}

/// Opens the scanner for a **single** scan optimized for **QR codes**.
///
/// Pushes a full-screen [ScannerScreen.singleScan] with a responsive 1:1
/// square overlay. Detection is locked to [BarcodeFormat.qrCode] to
/// eliminate accidental 1D reads.
///
/// Returns the decoded `String?`, or `null` if the user dismisses the
/// scanner.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [stackChildren] — Additional widgets layered on top of the camera preview.
/// * [onScanRejected] — Called when a scan is silently rejected.
/// * [overlayStyle] — Visual overlay customization. See [ScannerOverlayStyle].
/// * [offsetFromCenter] — Nudge for the scan window position.
/// * [toolBar] — Toolbar config. Defaults to a [StandardToolBar].
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// final qrCode = await scanQrCode(context);
/// if (qrCode != null) {
///   launchUrl(Uri.parse(qrCode));
/// }
/// ```
Future<String?> scanQrCode(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Called when a scan is silently rejected.
  void Function(String)? onScanRejected,

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset? offsetFromCenter,

  /// Toolbar configuration. Defaults to a [StandardToolBar].
  ScannerToolBar? toolBar = const StandardToolBar(),

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  return scanCustom(
    context,
    toolBar: toolBar,
    stackChildren: stackChildren,
    onScanRejected: onScanRejected,
    scannerViewConfig: ScannerViewConfig.qrCode(
      overlayStyle: overlayStyle,
      offsetFromCenter: offsetFromCenter,
    ),
    enableSoundAndVibration: enableSoundAndVibration,
    useDarkModeButtonTheme: useDarkModeButtonTheme,
    lensType: lensType,
    initialZoom: initialZoom,
  );
}

// MARK: - Batch

/// Opens the scanner in **batch** mode with a fully custom overlay.
///
/// Acts as a shopping cart: the user scans multiple items and each accepted
/// value is appended to an internal list. When the user closes the screen,
/// the accumulated `List<String>?` is returned. Returns `null` if the
/// navigator route is disposed without a result.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [stackChildren] — Additional widgets layered on top of the camera preview.
/// * [toolBar] — Toolbar config. Pass `null` to hide the toolbar entirely.
/// * [scannerViewConfig] — Full manual control over overlay shape, scan window,
///   and allowed barcode formats.
/// * [allowDuplicates] — When `false`, scans that match a value already in
///   the internal list are silently rejected (or routed to [onScanRejected]).
///   Defaults to `true`.
/// * [detectionTimeoutMs] — Minimum milliseconds between *any* two decode
///   callbacks from the native camera pipeline. Lower values increase
///   responsiveness but raise CPU load. Defaults to `250`.
/// * [sameItemCooldownMs] — Minimum milliseconds before the *same* barcode
///   value is accepted again. Prevents rapid-fire duplicates when the user
///   holds a barcode under the camera. Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [onScanRejected] — Fires when a scan is rejected due to
///   [allowDuplicates] being `false`.
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// final items = await scanCustomBatch(
///   context,
///   allowDuplicates: false,
///   onScanRejected: (dup) => showSnackBar('Already scanned: $dup'),
/// );
///
/// if (items != null && items.isNotEmpty) {
///   processItems(items);
/// }
/// ```
///
/// ### Errors
/// All camera exceptions are caught internally and logged via [debugPrint].
/// In the event of a camera error, the function returns `null`.
Future<List<String>?> scanCustomBatch(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Pass `null` to hide the toolbar.
  ScannerToolBar? toolBar,

  /// Full manual control over the overlay shape and allowed formats.
  ScannerViewConfig? scannerViewConfig,

  /// When `false`, matching duplicate scans are silently rejected.
  bool allowDuplicates = true,

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Fires when a scan is rejected due to duplicate rules.
  void Function(String)? onScanRejected,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  try {
    final List<String>? scannedItems =
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => ScannerScreen.multiscan(
              toolBar: toolBar,
              stackChildren: stackChildren,
              onScanRejected: onScanRejected,
              allowDuplicates: allowDuplicates,
              detectionTimeoutMs: detectionTimeoutMs,
              sameItemCooldownMs: sameItemCooldownMs,
              scannerViewConfig: scannerViewConfig,
              enableSoundAndVibration: enableSoundAndVibration,
              useDarkModeButtonTheme: useDarkModeButtonTheme,
              lensType: lensType,
              initialZoom: initialZoom,
            ),
          ),
        );

    if (scannedItems != null) {
      debugPrint('$kTag Successfully scanned: $scannedItems');
    }

    return scannedItems;
  } catch (e, stackTrace) {
    debugPrint('$kTag Error on scanning: $e\n$stackTrace');
    return null;
  }
}

/// Opens the scanner in **batch** mode optimized for **horizontal 1D barcodes**.
///
/// Combines the batch accumulation behaviour of [scanCustomBatch] with the
/// barcode-optimised overlay and format filtering of [scanBarcode]. The user
/// scans multiple items; on close the accumulated `List<String>?` is returned.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [stackChildren] — Extra widgets layered on top of the camera preview.
/// * [toolBar] — Toolbar config. Defaults to a [BatchToolBar] (includes a
///   scanned-items badge).
/// * [allowDuplicates] — Whether to accept the same barcode value more than
///   once. Defaults to `true`.
/// * [detectionTimeoutMs] — Minimum ms between decode callbacks. Defaults
///   to `250`.
/// * [sameItemCooldownMs] — Minimum ms before the same barcode can scan
///   again. Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [onScanRejected] — Fires on rejected duplicates.
/// * [offsetFromCenter] — Scan window position nudge.
/// * [overlayStyle] — Visual overlay customization. See [ScannerOverlayStyle].
/// * [allowedFormats] — Restricts detection. Intersected with the built-in
///   1D format set. An empty list (default) uses the full 1D set.
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// final barcodes = await scanBarcodeBatch(
///   context,
///   allowDuplicates: false,
///   allowedFormats: [BarcodeFormat.ean13],
/// );
/// ```
Future<List<String>?> scanBarcodeBatch(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Defaults to a [BatchToolBar].
  ScannerToolBar? toolBar = const BatchToolBar(),

  /// When `false`, matching duplicate scans are silently rejected.
  bool allowDuplicates = true,

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Fires when a scan is rejected due to duplicate rules.
  void Function(String)? onScanRejected,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset? offsetFromCenter,

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// Restricts detection to specific [BarcodeFormat]s.
  List<BarcodeFormat> allowedFormats = const [],

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  return scanCustomBatch(
    context,
    stackChildren: stackChildren,
    allowDuplicates: allowDuplicates,
    detectionTimeoutMs: detectionTimeoutMs,
    sameItemCooldownMs: sameItemCooldownMs,
    onScanRejected: onScanRejected,
    toolBar: toolBar,
    scannerViewConfig: ScannerViewConfig.barcode(
      overlayStyle: overlayStyle,
      offsetFromCenter: offsetFromCenter,
      allowedFormats: allowedFormats,
    ),
    enableSoundAndVibration: enableSoundAndVibration,
    useDarkModeButtonTheme: useDarkModeButtonTheme,
    lensType: lensType,
    initialZoom: initialZoom,
  );
}

/// Opens the scanner in **batch** mode optimized for **QR codes**.
///
/// Combines the batch accumulation behaviour of [scanCustomBatch] with the
/// QR-optimised square overlay and format lock of [scanQrCode]. Detection is
/// restricted to [BarcodeFormat.qrCode].
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [stackChildren] — Extra widgets layered on top of the camera preview.
/// * [toolBar] — Toolbar config. Defaults to a [BatchToolBar].
/// * [allowDuplicates] — Accept the same QR value more than once. Defaults
///   to `true`.
/// * [detectionTimeoutMs] — Minimum ms between decode callbacks. Defaults
///   to `250`.
/// * [sameItemCooldownMs] — Minimum ms before the same QR can scan again.
///   Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [onScanRejected] — Fires on rejected duplicates.
/// * [offsetFromCenter] — Scan window position nudge.
/// * [overlayStyle] — Visual overlay customization. See [ScannerOverlayStyle].
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// final qrCodes = await scanQrCodeBatch(context);
///
/// if (qrCodes != null) {
///   for (final code in qrCodes) {
///     print('Scanned QR: $code');
///   }
/// }
/// ```
Future<List<String>?> scanQrCodeBatch(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Defaults to a [BatchToolBar].
  ScannerToolBar? toolBar = const BatchToolBar(),

  /// When `false`, matching duplicate scans are silently rejected.
  bool allowDuplicates = true,

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Fires when a scan is rejected due to duplicate rules.
  void Function(String)? onScanRejected,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset? offsetFromCenter,

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  return scanCustomBatch(
    context,
    stackChildren: stackChildren,
    allowDuplicates: allowDuplicates,
    detectionTimeoutMs: detectionTimeoutMs,
    sameItemCooldownMs: sameItemCooldownMs,
    onScanRejected: onScanRejected,
    toolBar: toolBar,
    scannerViewConfig: ScannerViewConfig.qrCode(
      overlayStyle: overlayStyle,
      offsetFromCenter: offsetFromCenter,
    ),
    enableSoundAndVibration: enableSoundAndVibration,
    useDarkModeButtonTheme: useDarkModeButtonTheme,
    lensType: lensType,
    initialZoom: initialZoom,
  );
}


// MARK: - Stream

/// Opens the scanner in **stream** mode with a fully custom overlay.
///
/// Instead of accumulating results and returning them on pop, this function
/// fires the [onCameraScan] callback in **real-time** as each barcode is
/// successfully decoded. The `Future<void>` completes when the user closes
/// the scanner screen.
///
/// Internally this uses [ScannerScreen.multiscan] with the [onCameraScan]
/// callback wired in. A batch list is still accumulated behind the scenes
/// (accessible via the toolbar badge if a [BatchToolBar] is used), but the
/// primary data channel is the callback.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [onCameraScan] — **Required.** Called with the raw barcode `String`
///   every time a scan is accepted.
/// * [stackChildren] — Extra widgets layered on top of the camera preview.
/// * [toolBar] — Toolbar config. Pass `null` to hide the toolbar.
/// * [scannerViewConfig] — Full manual control over the overlay shape,
///   scan window, and allowed barcode formats.
/// * [allowDuplicates] — Accept the same value more than once. Defaults
///   to `true`.
/// * [detectionTimeoutMs] — Minimum ms between decode callbacks. Defaults
///   to `250`.
/// * [sameItemCooldownMs] — Minimum ms before the same barcode can scan
///   again. Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [onScanRejected] — Fires when a scan is rejected due to
///   [allowDuplicates] being `false`.
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// await scanCustomStream(
///   context,
///   onCameraScan: (code) {
///     print('Scanned: $code');
///   },
/// );
/// ```
///
/// ### Errors
/// Camera exceptions are caught internally and logged via [debugPrint].
Future<void> scanCustomStream(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Called with the raw barcode string on every accepted scan.
  required void Function(String) onCameraScan,

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Pass `null` to hide the toolbar.
  ScannerToolBar? toolBar,

  /// Full manual control over the overlay shape and allowed formats.
  ScannerViewConfig? scannerViewConfig,

  /// When `false`, matching duplicate scans are silently rejected.
  bool allowDuplicates = true,

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Fires when a scan is rejected due to duplicate rules.
  void Function(String)? onScanRejected,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  try {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ScannerScreen.multiscan(
          toolBar: toolBar,
          stackChildren: stackChildren,
          onScanRejected: onScanRejected,
          onCameraScan: onCameraScan,
          allowDuplicates: allowDuplicates,
          detectionTimeoutMs: detectionTimeoutMs,
          sameItemCooldownMs: sameItemCooldownMs,
          scannerViewConfig: scannerViewConfig,
          enableSoundAndVibration: enableSoundAndVibration,
          useDarkModeButtonTheme: useDarkModeButtonTheme,
          lensType: lensType,
          initialZoom: initialZoom,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('$kTag Error on scanning: $e\n$stackTrace');
  }
}

/// Opens the scanner in **stream** mode optimized for **horizontal 1D barcodes**.
///
/// Combines the real-time streaming behaviour of [scanCustomStream] with
/// the barcode-optimised overlay and format filtering of [scanBarcode].
/// Each accepted barcode fires the [onCameraScan] callback immediately.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [onCameraScan] — **Required.** Called with the raw barcode `String`
///   on every accepted scan.
/// * [stackChildren] — Extra widgets layered on top of the camera preview.
/// * [toolBar] — Toolbar config. Defaults to a [BatchToolBar].
/// * [allowDuplicates] — Accept the same value more than once. Defaults
///   to `true`.
/// * [detectionTimeoutMs] — Minimum ms between decode callbacks. Defaults
///   to `250`.
/// * [sameItemCooldownMs] — Minimum ms before the same barcode can scan
///   again. Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [onScanRejected] — Fires on rejected duplicates.
/// * [overlayStyle] — Visual overlay customization. See [ScannerOverlayStyle].
/// * [offsetFromCenter] — Scan window position nudge.
/// * [allowedFormats] — Restricts detection. Intersected with the built-in
///   1D format set. An empty list (default) uses the full 1D set.
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// await scanBarcodeStream(
///   context,
///   onCameraScan: (code) {
///     print('Scanned: $code');
///   },
/// );
/// ```
Future<void> scanBarcodeStream(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Called with the raw barcode string on every accepted scan.
  required void Function(String) onCameraScan,

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Defaults to a [BatchToolBar].
  ScannerToolBar? toolBar = const BatchToolBar(),

  /// When `false`, matching duplicate scans are silently rejected.
  bool allowDuplicates = true,

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Fires when a scan is rejected due to duplicate rules.
  void Function(String)? onScanRejected,

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset? offsetFromCenter,

  /// Restricts detection to specific [BarcodeFormat]s.
  List<BarcodeFormat> allowedFormats = const [],

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async => scanCustomStream(
  context,
  stackChildren: stackChildren,
  onScanRejected: onScanRejected,
  onCameraScan: onCameraScan,
  allowDuplicates: allowDuplicates,
  detectionTimeoutMs: detectionTimeoutMs,
  sameItemCooldownMs: sameItemCooldownMs,
  scannerViewConfig: ScannerViewConfig.barcode(
    overlayStyle: overlayStyle,
    offsetFromCenter: offsetFromCenter,
    allowedFormats: allowedFormats,
  ),
  toolBar: toolBar,
  enableSoundAndVibration: enableSoundAndVibration,
  useDarkModeButtonTheme: useDarkModeButtonTheme,
  lensType: lensType,
  initialZoom: initialZoom,
);

/// Opens the scanner in **stream** mode optimized for **QR codes**.
///
/// Combines the real-time streaming behaviour of [scanCustomStream] with
/// the QR-optimised square overlay and format lock of [scanQrCode].
/// Detection is restricted to [BarcodeFormat.qrCode].
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [onCameraScan] — **Required.** Called with the raw QR `String` on
///   every accepted scan.
/// * [stackChildren] — Extra widgets layered on top of the camera preview.
/// * [toolBar] — Toolbar config. Defaults to a [BatchToolBar].
/// * [allowDuplicates] — Accept the same QR value more than once. Defaults
///   to `true`.
/// * [detectionTimeoutMs] — Minimum ms between decode callbacks. Defaults
///   to `250`.
/// * [sameItemCooldownMs] — Minimum ms before the same QR can scan again.
///   Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [onScanRejected] — Fires on rejected duplicates.
/// * [overlayStyle] — Visual overlay customization. See [ScannerOverlayStyle].
/// * [offsetFromCenter] — Scan window position nudge.
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// await scanQrCodeStream(
///   context,
///   onCameraScan: (code) {
///     print('Scanned QR: $code');
///   },
/// );
/// ```
Future<void> scanQrCodeStream(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Called with the raw barcode string on every accepted scan.
  required void Function(String) onCameraScan,

  /// Additional widgets layered on top of the camera preview.
  List<Widget>? stackChildren,

  /// Toolbar configuration. Defaults to a [BatchToolBar].
  ScannerToolBar? toolBar = const BatchToolBar(),

  /// When `false`, matching duplicate scans are silently rejected.
  bool allowDuplicates = true,

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Fires when a scan is rejected due to duplicate rules.
  void Function(String)? onScanRejected,

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset? offsetFromCenter,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async => scanCustomStream(
  context,
  stackChildren: stackChildren,
  onScanRejected: onScanRejected,
  onCameraScan: onCameraScan,
  allowDuplicates: allowDuplicates,
  detectionTimeoutMs: detectionTimeoutMs,
  sameItemCooldownMs: sameItemCooldownMs,
  scannerViewConfig: ScannerViewConfig.qrCode(
    overlayStyle: overlayStyle,
    offsetFromCenter: offsetFromCenter,
  ),
  toolBar: toolBar,
  enableSoundAndVibration: enableSoundAndVibration,
  useDarkModeButtonTheme: useDarkModeButtonTheme,
  lensType: lensType,
  initialZoom: initialZoom,
);

/// Launches the **Point of Sale (POS) Barcode Scanner**.
///
/// Pushes a full-screen [PosBarcodeScannerScreen] optimised for retail/warehouse
/// workflows. The screen includes:
///
/// * A **barcode-optimised overlay** with a wide, landscape-oriented scan window.
/// * **Quantity control buttons** (+ / −) positioned below the scan window so
///   the cashier can set a quantity *before* scanning.
/// * A **reactive badge** in the toolbar showing the total scanned items,
///   tappable to reveal a bottom-sheet list of all scans.
/// * A **"ghost pulse"** success animation that flashes the screen on each
///   accepted scan.
///
/// The [onScan] callback fires each time a barcode is successfully scanned,
/// passing both the raw barcode `String` and the current quantity `int`.
/// After each scan the quantity resets to `1`.
///
/// ### Parameters
///
/// * [context] — A [BuildContext] with a valid [Navigator] ancestor.
/// * [onScan] — **Required.** Called with `(String barcode, int quantity)`
///   on every accepted scan.
/// * [allowedFormats] — Restricts detection to specific [BarcodeFormat]s.
///   Empty list (default) accepts the standard 1D set.
/// * [detectionTimeoutMs] — Minimum ms between decode callbacks. Defaults
///   to `250`.
/// * [sameItemCooldownMs] — Minimum ms before the same barcode can scan
///   again. Defaults to `1500`.
/// * [enableSoundAndVibration] — Haptic and audio feedback. Defaults to `true`.
/// * [offsetFromCenter] — Vertical/horizontal nudge for the scan window.
///   Defaults to `Offset(0, -180)` (raised above center to leave room for
///   the quantity buttons below).
/// * [overlayStyle] — Visual overlay customization. See [ScannerOverlayStyle].
/// * [useDarkModeButtonTheme] — Dark button backgrounds. Defaults to `true`.
/// * [qtyButtonsBottomPadding] — Bottom padding for the quantity buttons.
///   Defaults to `230`. **Asserts** that the value is greater than `0`.
/// * [closeButtonLabel] — Custom label for the close button. Defaults to
///   `'Close Camera'`.
/// * [successPulseColor] — The color of the full-screen ghost pulse on a
///   successful scan. Defaults to [Colors.cyanAccent].
/// * [lensType] — Physical camera lens. Defaults to [ScannerLensType.any].
///   See [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — Initial zoom scale (0.0 – 1.0). iOS, macOS, and
///   Android only. Defaults to `null`.
///
/// ### Example
/// ```dart
/// showPosBarcodeScanner(
///   context,
///   onScan: (barcode, quantity) {
///     print('Added $quantity × $barcode to cart');
///   },
///   allowedFormats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
///   successPulseColor: Colors.greenAccent,
/// );
/// ```
///
/// ### Errors
/// Camera exceptions are caught internally and logged via [debugPrint].
void showPosBarcodeScanner(
  /// A [BuildContext] with a valid [Navigator] ancestor.
  BuildContext context, {

  /// Called with `(String barcode, int quantity)` on every accepted scan.
  required void Function(String barcode, int quantity) onScan,

  /// Restricts detection to specific [BarcodeFormat]s.
  List<BarcodeFormat> allowedFormats = const <BarcodeFormat>[],

  /// Minimum milliseconds between decode callbacks.
  int detectionTimeoutMs = 250,

  /// Minimum milliseconds before the same barcode is accepted again.
  int sameItemCooldownMs = 1500,

  /// Whether to trigger haptic feedback and an audible beep on success.
  bool enableSoundAndVibration = true,

  /// Vertical/horizontal nudge applied to the scan window position.
  Offset offsetFromCenter = const Offset(0, -180),

  /// Visual customization for the overlay border, corner radius, etc.
  ScannerOverlayStyle? overlayStyle,

  /// When `true`, toolbar buttons use a dark translucent background.
  bool useDarkModeButtonTheme = true,

  /// Bottom padding for the quantity buttons. Must be > 0.
  double qtyButtonsBottomPadding = 230,

  /// Custom label for the close button.
  String? closeButtonLabel,

  /// The color of the full-screen ghost pulse on a successful scan.
  Color? successPulseColor,

  /// The physical camera lens to activate.
  ScannerLensType lensType = ScannerLensType.any,

  /// The initial zoom scale for the camera (0.0 – 1.0).
  double? initialZoom,
}) async {
  try {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PosBarcodeScannerScreen(
          onScan: onScan,
          overlayStyle: overlayStyle,
          allowedFormats: allowedFormats,
          closeButtonLabel: closeButtonLabel,
          offsetFromCenter: offsetFromCenter,
          detectionTimeoutMs: detectionTimeoutMs,
          sameItemCooldownMs: sameItemCooldownMs,
          enableSoundAndVibration: enableSoundAndVibration,
          useDarkModeButtonTheme: useDarkModeButtonTheme,
          qtyButtonsBottomPadding: qtyButtonsBottomPadding,
          successPulseColor: successPulseColor,
          lensType: lensType,
          initialZoom: initialZoom,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('$kTag Error on pos barcode scanning: $e\n$stackTrace');
  }
}
