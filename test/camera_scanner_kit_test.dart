import 'package:flutter_test/flutter_test.dart';

import 'package:camera_scanner_kit/camera_scanner_kit.dart';

void main() {
  test('ScannerOverlayStyle defaults are set correctly', () {
    const style = ScannerOverlayStyle();
    expect(style.opacity, 0.5);
    expect(style.borderWidth, 2.5);
    expect(style.borderRadius, 12.0);
  });
}
