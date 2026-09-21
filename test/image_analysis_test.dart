import 'package:camera_scanner_kit/camera_scanner_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A fake platform implementation used to test [scanImageFile] and
/// [scanImageFileAll] without a real Android/iOS runtime.
///
/// [MobileScannerPlatform.instance] has a public setter guarded by
/// `PlatformInterface`'s token check, and subclassing [MobileScannerPlatform]
/// inherits that token automatically — no real device or method channel is
/// needed to exercise the pass-through logic.
class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  /// Set by a test to control what [analyzeImage] returns.
  BarcodeCapture? Function(String path, List<BarcodeFormat> formats)?
  onAnalyzeImage;

  /// Records every call made, so tests can assert on ordering / arguments.
  final List<String> calls = [];

  /// Delays before resolving, to let tests observe overlapping calls.
  Duration delay = Duration.zero;

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    calls.add(path);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final handler = onAnalyzeImage;
    if (handler == null) {
      return null;
    }
    return handler(path, formats);
  }
}

void main() {
  late MobileScannerPlatform realPlatform;
  late _FakeMobileScannerPlatform fake;

  setUp(() {
    realPlatform = MobileScannerPlatform.instance;
    fake = _FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fake;
  });

  tearDown(() {
    MobileScannerPlatform.instance = realPlatform;
  });

  group('scanImageFileAll', () {
    test('returns every decoded value, in order', () async {
      fake.onAnalyzeImage = (path, formats) => const BarcodeCapture(
        barcodes: [
          Barcode(rawValue: 'first'),
          Barcode(rawValue: 'second'),
        ],
      );

      final result = await scanImageFileAll('/tmp/shelf.jpg');

      expect(result, ['first', 'second']);
    });

    test('drops a null rawValue without masking a later valid code', () async {
      // A detected code's rawValue can itself be null (binary content that
      // isn't UTF-8 decodable). That must not be returned as a null entry,
      // nor treated as "nothing found" when a real code follows it.
      fake.onAnalyzeImage = (path, formats) => const BarcodeCapture(
        barcodes: [
          Barcode(rawValue: null),
          Barcode(rawValue: 'valid'),
        ],
      );

      final result = await scanImageFileAll('/tmp/binary.jpg');

      expect(result, ['valid']);
    });

    test('a null capture yields an empty list', () async {
      fake.onAnalyzeImage = (path, formats) => null;

      expect(await scanImageFileAll('/tmp/none.jpg'), isEmpty);
    });

    test('a capture with no barcodes yields an empty list', () async {
      fake.onAnalyzeImage = (path, formats) => const BarcodeCapture();

      expect(await scanImageFileAll('/tmp/blank.jpg'), isEmpty);
    });

    test('forwards ScannerBarcodeFormat mapped to BarcodeFormat', () async {
      List<BarcodeFormat>? received;
      fake.onAnalyzeImage = (path, formats) {
        received = formats;
        return null;
      };

      await scanImageFileAll(
        '/tmp/code.jpg',
        allowedFormats: const [
          ScannerBarcodeFormat.qrCode,
          ScannerBarcodeFormat.ean13,
        ],
      );

      expect(received, [BarcodeFormat.qrCode, BarcodeFormat.ean13]);
    });

    test('an empty allow-list is forwarded empty (all formats)', () async {
      List<BarcodeFormat>? received;
      fake.onAnalyzeImage = (path, formats) {
        received = formats;
        return null;
      };

      await scanImageFileAll('/tmp/code.jpg');

      expect(received, isEmpty);
    });

    test('UnsupportedError is swallowed, not thrown', () async {
      fake.onAnalyzeImage = (path, formats) =>
          throw UnsupportedError('not supported on this platform');

      await expectLater(
        scanImageFileAll('/tmp/code.jpg'),
        completion(isEmpty),
      );
    });

    test('MobileScannerBarcodeException is swallowed, not thrown', () async {
      fake.onAnalyzeImage = (path, formats) =>
          throw const MobileScannerBarcodeException('corrupt file');

      await expectLater(
        scanImageFileAll('/tmp/corrupt.jpg'),
        completion(isEmpty),
      );
    });

    test('overlapping calls are serialized, not clobbered', () async {
      fake.delay = const Duration(milliseconds: 30);
      var callIndex = 0;
      fake.onAnalyzeImage = (path, formats) {
        callIndex++;
        return BarcodeCapture(barcodes: [Barcode(rawValue: 'call-$callIndex')]);
      };

      // Fired without awaiting the first — the regression scenario for a
      // double-tapped "scan from gallery" button.
      final first = scanImageFileAll('/tmp/a.jpg');
      final second = scanImageFileAll('/tmp/b.jpg');

      final results = await Future.wait([first, second]);

      // Both calls must resolve (neither Future hangs forever), each with
      // its own result rather than one clobbering the other.
      expect(results[0], ['call-1']);
      expect(results[1], ['call-2']);
      expect(fake.calls, ['/tmp/a.jpg', '/tmp/b.jpg']);
    });
  });

  group('scanImageFile', () {
    test('returns the first decoded value', () async {
      fake.onAnalyzeImage = (path, formats) => const BarcodeCapture(
        barcodes: [
          Barcode(rawValue: 'first'),
          Barcode(rawValue: 'second'),
        ],
      );

      expect(await scanImageFile('/tmp/shelf.jpg'), 'first');
    });

    test('returns null when nothing is found', () async {
      fake.onAnalyzeImage = (path, formats) => null;

      expect(await scanImageFile('/tmp/none.jpg'), isNull);
    });

    test('returns null rather than throwing on failure', () async {
      fake.onAnalyzeImage = (path, formats) =>
          throw UnsupportedError('not supported on this platform');

      expect(await scanImageFile('/tmp/code.jpg'), isNull);
    });

    test('forwards allowedFormats like scanImageFileAll', () async {
      List<BarcodeFormat>? received;
      fake.onAnalyzeImage = (path, formats) {
        received = formats;
        return null;
      };

      await scanImageFile(
        '/tmp/code.jpg',
        allowedFormats: const [ScannerBarcodeFormat.qrCode],
      );

      expect(received, [BarcodeFormat.qrCode]);
    });
  });
}
