/// Headless decoding of barcodes and QR codes from an existing image file —
/// a saved QR code picked from the gallery, a screenshot, a photo of a shelf
/// label.
///
/// Unlike every function in `functions.dart`, these do not push a
/// [ScannerScreen] and take no [BuildContext]: they are a pure pass-through
/// to `mobile_scanner`'s file analyzer, kept in their own file for exactly
/// that reason. Picking the file is the host app's job — see the README's
/// *Scanning from an Image File* section for an `image_picker` recipe.
///
/// Only Android and physical iOS devices can analyze image files; see
/// [scanImageFileAll] for what happens elsewhere.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:mobile_scanner/mobile_scanner.dart' show MobileScannerPlatform;

import '_constants.dart';
import 'functions.dart' show scanBarcode, scanQrCode;
import 'mobile_scanner_interop.dart';
import 'scanner_barcode_format.dart';
import 'scanner_screen/scanner_screen.dart' show ScannerScreen;

/// Chains every call through the previous one so two overlapping analyses
/// can never run at once.
///
/// This exists because of a native Android limitation: `mobile_scanner`'s
/// platform channel handler keeps a single pending-result slot for
/// `analyzeImage`, so a second call issued before the first completes
/// overwrites it — leaving the first caller's [Future] pending forever. A
/// double-tapped "scan from gallery" button would otherwise hang.
Future<void> _analysisQueue = Future<void>.value();

/// Decodes every barcode or QR code found in the image at [filePath].
///
/// This is the primitive both this package and `mobile_scanner` build on —
/// [scanImageFile] is a thin wrapper that returns just the first value.
/// Prefer this one when the image may contain more than one code (a shelf
/// photo, a screenshot of several tickets); reach for [scanImageFile] when
/// you expect exactly one, such as a single saved QR code.
///
/// [allowedFormats] restricts which symbologies are attempted. An empty list
/// (the default) accepts every format the device supports — see
/// [ScannerBarcodeFormat] for the full set and its "empty means all"
/// convention.
///
/// Returns an empty list when the image contains no recognizable code, when
/// the file cannot be read, or on any platform other than Android or a
/// physical iOS device (the iOS Simulator cannot analyze image files at
/// all). Every failure is logged via [debugPrint] rather than thrown, so
/// this function never throws.
Future<List<String>> scanImageFileAll(
  String filePath, {
  List<ScannerBarcodeFormat> allowedFormats = const [],
}) {
  // No `MobileScannerController` is created here on purpose. The controller
  // only wraps this same platform call, but its `dispose()` can tear down
  // the platform's camera session when no other controller currently owns
  // it — a real risk given this package's inline scanner can be mounted at
  // the same time as a gallery pick. Talking to the platform singleton
  // directly analyzes the file without touching the camera or permissions,
  // and cannot disturb a live scan.
  final future = _analysisQueue.then((_) async {
    try {
      final capture = await MobileScannerPlatform.instance.analyzeImage(
        filePath,
        formats: allowedFormats.mobileScannerFormats,
      );
      final barcodes = capture?.barcodes ?? const [];
      // A detected code's raw value can itself be null (binary content that
      // isn't UTF-8 decodable) — drop those rather than surfacing them as a
      // false "nothing found" or a misleading null entry.
      return barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .toList();
    } on UnsupportedError catch (e) {
      debugPrint(
        '$kTag scanImageFile(s) is not supported here: $e\n'
        'This is expected on the iOS Simulator (it cannot analyze image '
        'files at all — test on a physical device), on web, and on desktop '
        'platforms. Only Android and physical iOS devices are supported.',
      );
      return const <String>[];
    } catch (e, stackTrace) {
      debugPrint('$kTag Error analyzing image file: $e\n$stackTrace');
      return const <String>[];
    }
  });
  // Every call awaits its own result via this future, but the queue itself
  // must never fail — a rejected `_analysisQueue` would poison every call
  // chained after it. The two catches above already return normally, so
  // this failsafe should not trigger in practice.
  _analysisQueue = future.then((_) {}, onError: (_) {});
  return future;
}

/// Decodes the first barcode or QR code found in the image at [filePath].
///
/// A thin wrapper around [scanImageFileAll] — see that function for
/// [allowedFormats], platform support and error behavior. Returns `null`
/// when no code is found, matching [scanBarcode] and [scanQrCode].
Future<String?> scanImageFile(
  String filePath, {
  List<ScannerBarcodeFormat> allowedFormats = const [],
}) async {
  final results = await scanImageFileAll(
    filePath,
    allowedFormats: allowedFormats,
  );
  return results.isEmpty ? null : results.first;
}
