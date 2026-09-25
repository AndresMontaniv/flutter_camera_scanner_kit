import 'dart:io';

import 'package:flutter/services.dart';

/// One real image from `assets/test_images/` plus what it should decode to.
///
class TestImageCase {
  const TestImageCase({
    required this.asset,
    required this.description,
    required this.expected,
  });

  final String asset;
  final String description;

  /// Every value the image should yield. Compared as a set: the order of
  /// multi-barcode results is not guaranteed.
  final Set<String> expected;

  String get fileName => asset.split('/').last;
}

/// The free TEC-IT generator that produced the QR images appends this suffix
/// to the text typed into it, so it is part of the encoded payload.
const qrPayload = 'This is a QR Code by TEC-IT';

/// Expected values are what a decoder reports, so EAN codes include the check
/// digit that the printed digits omit. Confirmed against Apple's Vision
/// framework as a second, independent decoder.
const testImageCases = <TestImageCase>[
  TestImageCase(
    asset: 'assets/test_images/code_128_example.png',
    description: 'Code 128, blue background',
    expected: {'ABC-abc-1234'},
  ),
  TestImageCase(
    asset: 'assets/test_images/ean_13_example.png',
    description: 'EAN-13, no background',
    expected: {'9780201379624'},
  ),
  TestImageCase(
    asset: 'assets/test_images/qr_code_example_no_bg.png',
    description: 'QR code, no background',
    expected: {qrPayload},
  ),
  TestImageCase(
    asset: 'assets/test_images/qr_code_example_blue_bg.jpg',
    description: 'QR code, blue background',
    expected: {qrPayload},
  ),
  TestImageCase(
    asset: 'assets/test_images/multi_1D_barcodes_example.jpg',
    description: 'Code 128 + EAN-13 + EAN-8',
    expected: {'ABC-abc-1234', '9780201379624', '90311017'},
  ),
  TestImageCase(
    asset: 'assets/test_images/multi_barcode_blue_bg.jpg',
    description: 'QR code + EAN-8, blue background',
    expected: {qrPayload, '90311017'},
  ),
  TestImageCase(
    asset: 'assets/test_images/qr_code_with_json.jpg',
    description: 'QR code holding JSON, blue background',
    expected: {'{\n  "id": 1,\n  "name": "Ross Geller"\n}'},
  ),
];

/// Copies a bundled asset to a temp file and returns its path.
///
/// The native decoders read from the file system, not from the asset bundle.
Future<String> materializeAsset(String asset) async {
  final data = await rootBundle.load(asset);
  final file = File('${Directory.systemTemp.path}/${asset.split('/').last}');
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return file.path;
}
