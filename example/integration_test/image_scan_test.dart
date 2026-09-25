import 'dart:convert';

import 'package:camera_scanner_kit/camera_scanner_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_images.dart';

/// Decodes real images through the native analyzer (ML Kit on Android,
/// Vision on iOS), so it must run on a device:
///
///   flutter test integration_test -d `deviceId`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  TestImageCase byFile(String name) =>
      testImageCases.firstWhere((c) => c.fileName == name);

  group('scanImageFileAll', () {
    for (final testCase in testImageCases) {
      testWidgets('${testCase.fileName} (${testCase.description})', (
        tester,
      ) async {
        final path = await materializeAsset(testCase.asset);

        final found = await scanImageFileAll(path);

        expect(found.toSet(), testCase.expected);
        expect(found, hasLength(testCase.expected.length));
      });
    }
  });

  group('scanImageFile', () {
    for (final testCase in testImageCases) {
      testWidgets('${testCase.fileName} returns a code from the image', (
        tester,
      ) async {
        final path = await materializeAsset(testCase.asset);

        final first = await scanImageFile(path);

        expect(first, isNotNull);
        expect(testCase.expected, contains(first));
      });
    }
  });

  group('allowedFormats', () {
    testWidgets('code128 keeps only the Code 128 value', (tester) async {
      final path = await materializeAsset(
        byFile('multi_1D_barcodes_example.jpg').asset,
      );

      final found = await scanImageFileAll(
        path,
        allowedFormats: [ScannerBarcodeFormat.code128],
      );

      expect(found, ['ABC-abc-1234']);
    });

    testWidgets('qrCode keeps only the QR value', (tester) async {
      final path = await materializeAsset(
        byFile('multi_barcode_blue_bg.jpg').asset,
      );

      final found = await scanImageFileAll(
        path,
        allowedFormats: [ScannerBarcodeFormat.qrCode],
      );

      expect(found, [qrPayload]);
    });

    testWidgets('a format the image lacks yields nothing', (tester) async {
      final path = await materializeAsset(
        byFile('qr_code_example_no_bg.png').asset,
      );

      final found = await scanImageFileAll(
        path,
        allowedFormats: [ScannerBarcodeFormat.ean13],
      );

      expect(found, isEmpty);
    });
  });

  testWidgets('JSON QR payload round-trips through jsonDecode', (
    tester,
  ) async {
    final path = await materializeAsset(
      byFile('qr_code_with_json.jpg').asset,
    );

    final value = await scanImageFile(path);

    expect(jsonDecode(value!), {'id': 1, 'name': 'Ross Geller'});
  });

  group('failure handling', () {
    testWidgets('a missing file yields [] / null without throwing', (
      tester,
    ) async {
      const missing = '/definitely/not/here.png';

      expect(await scanImageFileAll(missing), isEmpty);
      expect(await scanImageFile(missing), isNull);
    });
  });

  testWidgets('concurrent calls both complete with correct results', (
    tester,
  ) async {
    final a = await materializeAsset(byFile('code_128_example.png').asset);
    final b = await materializeAsset(byFile('qr_code_example_no_bg.png').asset);

    final results = await Future.wait([
      scanImageFileAll(a),
      scanImageFileAll(b),
    ]).timeout(const Duration(seconds: 30));

    expect(results[0], ['ABC-abc-1234']);
    expect(results[1], [qrPayload]);
  });
}
