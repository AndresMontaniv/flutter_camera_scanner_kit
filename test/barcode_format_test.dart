import 'package:camera_scanner_kit/camera_scanner_kit.dart';
// Internal imports: the mapper and the filtering rules are deliberately kept
// out of the public API — exposing them is exactly the leak this suite guards
// against — but both are pure functions and worth testing directly.
import 'package:camera_scanner_kit/src/format_resolution.dart';
import 'package:camera_scanner_kit/src/mobile_scanner_interop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('ScannerBarcodeFormat', () {
    test('exposes no sentinel values', () {
      // `unknown` identifies a decode *result* and `all` is expressed by an
      // empty allow-list, so neither has a coherent meaning as an entry in
      // one. Both are deliberately absent.
      final names = ScannerBarcodeFormat.values.map((f) => f.name).toList();

      expect(names, isNot(contains('unknown')));
      expect(names, isNot(contains('all')));
    });

    test('every value maps to a real mobile_scanner format', () {
      for (final format in ScannerBarcodeFormat.values) {
        final mapped = format.mobileScannerFormat;

        expect(
          mapped,
          isNot(BarcodeFormat.unknown),
          reason: '${format.name} must not map to the unknown sentinel',
        );
        expect(
          mapped,
          isNot(BarcodeFormat.all),
          reason: '${format.name} must not map to the all sentinel',
        );
      }
    });

    test('no two values collapse onto the same symbology', () {
      // Guards the `itf` / `itf14` trap: they are distinct enum constants in
      // mobile_scanner but share raw value 128, so comparing the mapped enum
      // constants alone would not catch a duplicate mapping.
      final rawValues = ScannerBarcodeFormat.values
          .map((f) => f.mobileScannerFormat.rawValue)
          .toList();

      expect(rawValues.toSet(), hasLength(rawValues.length));
    });

    test('covers every symbology mobile_scanner supports', () {
      // Forward-compatibility tripwire. If a mobile_scanner upgrade adds a
      // format, this fails and tells us to add the matching value — otherwise
      // the new symbology would be silently unreachable through this package.
      final upstream = BarcodeFormat.values
          .where((f) => f != BarcodeFormat.unknown && f != BarcodeFormat.all)
          // `itf` and `itf14` are the same symbology under two names.
          .map((f) => f.rawValue)
          .toSet();
      final covered = ScannerBarcodeFormat.values
          .map((f) => f.mobileScannerFormat.rawValue)
          .toSet();

      expect(
        covered,
        upstream,
        reason:
            'ScannerBarcodeFormat is out of sync with mobile_scanner. '
            'Add the missing value(s) and map them in mobile_scanner_interop.dart.',
      );
    });
  });

  group('resolveEffectiveFormats', () {
    test('1D mode with an empty allow-list yields the full retail set', () {
      final result = resolveEffectiveFormats(
        allowed: const [],
        restrictTo1D: true,
      );

      expect(result, horizontal1DFormats);
      expect(result, hasLength(9));
    });

    test('1D mode drops 2D formats from a caller-supplied subset', () {
      // The whole point of the intersection: a square *window* must never
      // start decoding QR codes just because the caller asked for it.
      final result = resolveEffectiveFormats(
        allowed: const [
          ScannerBarcodeFormat.ean13,
          ScannerBarcodeFormat.qrCode,
        ],
        restrictTo1D: true,
      );

      expect(result, [ScannerBarcodeFormat.ean13]);
    });

    test('1D mode with an all-2D subset yields nothing', () {
      final result = resolveEffectiveFormats(
        allowed: const [
          ScannerBarcodeFormat.qrCode,
          ScannerBarcodeFormat.aztec,
        ],
        restrictTo1D: true,
      );

      expect(result, isEmpty);
    });

    test('1D mode preserves a valid subset without widening it', () {
      final result = resolveEffectiveFormats(
        allowed: const [
          ScannerBarcodeFormat.ean13,
          ScannerBarcodeFormat.code128,
        ],
        restrictTo1D: true,
      );

      expect(result, [
        ScannerBarcodeFormat.ean13,
        ScannerBarcodeFormat.code128,
      ]);
    });

    test('unrestricted mode passes the caller list through unchanged', () {
      const allowed = [
        ScannerBarcodeFormat.qrCode,
        ScannerBarcodeFormat.dataMatrix,
      ];

      expect(
        resolveEffectiveFormats(allowed: allowed, restrictTo1D: false),
        allowed,
      );
    });

    test('unrestricted mode keeps an empty list empty', () {
      // Empty means "accept everything the device supports" — it must reach
      // the controller as-is rather than being expanded to the 1D set.
      expect(
        resolveEffectiveFormats(allowed: const [], restrictTo1D: false),
        isEmpty,
      );
    });

    test('the 1D retail set contains no 2D symbologies', () {
      const twoDimensional = {
        ScannerBarcodeFormat.qrCode,
        ScannerBarcodeFormat.microQrCode,
        ScannerBarcodeFormat.dataMatrix,
        ScannerBarcodeFormat.aztec,
        ScannerBarcodeFormat.pdf417,
        ScannerBarcodeFormat.maxiCode,
      };

      expect(
        horizontal1DFormats.toSet().intersection(twoDimensional),
        isEmpty,
      );
    });
  });

  group('ScannerViewConfig format wiring', () {
    test('.qrCode locks the allow-list to QR only', () {
      expect(
        const ScannerViewConfig.qrCode().allowedFormats,
        [ScannerBarcodeFormat.qrCode],
      );
    });

    test(
      '.barcode defaults to an empty list, resolved later to the 1D set',
      () {
        const config = ScannerViewConfig.barcode();

        expect(config.allowedFormats, isEmpty);
        expect(
          resolveEffectiveFormats(
            allowed: config.allowedFormats,
            restrictTo1D: true,
          ),
          horizontal1DFormats,
        );
      },
    );

    test('windowShape never widens the allow-list', () {
      // Geometry is independent of symbology: a square window still resolves
      // to the 1D-only set.
      const config = ScannerViewConfig.barcode(
        windowShape: BarcodeWindowShape.square,
      );

      expect(
        resolveEffectiveFormats(
          allowed: config.allowedFormats,
          restrictTo1D: true,
        ),
        horizontal1DFormats,
      );
    });
  });
}
