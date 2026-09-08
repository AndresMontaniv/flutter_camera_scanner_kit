import 'package:camera_scanner_kit/camera_scanner_kit.dart';
// Internal imports: the scan-window geometry is deliberately not part of the
// public API, but it is pure arithmetic and worth testing directly.
import 'package:camera_scanner_kit/src/prebuilt_screens/pos_window_geometry.dart';
import 'package:camera_scanner_kit/src/widgets/scanner_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// A representative modern phone: 390 x 844 lp with a notch and a home bar.
const Size _phone = Size(390, 844);
const EdgeInsets _phonePadding = EdgeInsets.only(top: 47, bottom: 34);

// The width every barcode window uses on [_phone]:
// 390 (shortest side) * 0.85 = 331.5, inside the [250, 400] clamp.
const double _phoneWindowWidth = 331.5;

void main() {
  test('ScannerOverlayStyle defaults are set correctly', () {
    const style = ScannerOverlayStyle();
    expect(style.opacity, 0.5);
    expect(style.borderWidth, 2.5);
    expect(style.borderRadius, 12.0);
  });

  group('barcodeWindowSize', () {
    test('standard keeps the historic fixed 130 lp height', () {
      final size = barcodeWindowSize(_phone, BarcodeWindowShape.standard);
      expect(size.width, _phoneWindowWidth);
      expect(size.height, 130.0);
    });

    test('tall is 60% of the responsive width', () {
      final size = barcodeWindowSize(_phone, BarcodeWindowShape.tall);
      expect(size.width, _phoneWindowWidth);
      expect(size.height, closeTo(_phoneWindowWidth * 0.60, 0.001));
    });

    test('square is genuinely 1:1', () {
      final size = barcodeWindowSize(_phone, BarcodeWindowShape.square);
      expect(size.height, size.width);
    });

    test('square stays 1:1 across wildly different screens', () {
      for (final screen in const [
        Size(320, 568), // small phone — hits the 250 lp min-width clamp
        Size(390, 844), // modern phone
        Size(1024, 1366), // tablet — hits the 400 lp max-width clamp
      ]) {
        final size = barcodeWindowSize(screen, BarcodeWindowShape.square);
        expect(
          size.height,
          size.width,
          reason: 'square must be 1:1 on $screen',
        );
      }
    });

    test('width clamps at both bounds regardless of shape', () {
      for (final shape in BarcodeWindowShape.values) {
        // 320 * 0.85 = 272 -> above the 250 floor, so not yet clamped.
        expect(barcodeWindowSize(const Size(320, 568), shape).width, 272.0);
        // 200 * 0.85 = 170 -> clamped up to the 250 floor.
        expect(barcodeWindowSize(const Size(200, 400), shape).width, 250.0);
        // 1024 * 0.85 = 870.4 -> clamped down to the 400 ceiling.
        expect(barcodeWindowSize(const Size(1024, 1366), shape).width, 400.0);
      }
    });
  });

  group('barcodeScanWindow', () {
    test('standard reproduces the historic 1.2.0 rect exactly', () {
      // The 1.2.0 formula was an unconditional
      //   Rect.fromCenter(center: size.center(offset), width: w, height: 130)
      // with no fitting. On a 390x844 screen at the POS offset of (0, -180):
      //   centre = (195, 422 - 180) = (195, 242)
      //   half   = (165.75, 65)
      final rect = barcodeScanWindow(
        _phone,
        _phonePadding,
        const Offset(0, -180),
        BarcodeWindowShape.standard,
      );

      expect(rect.left, closeTo(195 - 165.75, 0.001));
      expect(rect.top, closeTo(242 - 65, 0.001));
      expect(rect.width, closeTo(_phoneWindowWidth, 0.001));
      expect(rect.height, 130.0);
    });

    test('standard is never repositioned, even where it would overlap', () {
      // A small device at the POS offset genuinely overlaps the toolbar today.
      // The fit deliberately does NOT run for `standard`, so that pre-existing
      // geometry is preserved byte-for-byte rather than silently corrected.
      const small = Size(320, 568);
      final rect = barcodeScanWindow(
        small,
        const EdgeInsets.only(top: 20),
        const Offset(0, -180),
        BarcodeWindowShape.standard,
      );
      expect(rect.center.dy, closeTo(568 / 2 - 180, 0.001));
    });

    test('square is pushed clear of the toolbar on a short screen', () {
      const small = Size(320, 568);
      const padding = EdgeInsets.only(top: 20, bottom: 0);
      final rect = barcodeScanWindow(
        small,
        padding,
        const Offset(0, -180), // deliberately too high for a 272 lp window
        BarcodeWindowShape.square,
      );

      expect(
        rect.top,
        greaterThanOrEqualTo(padding.top + kToolbarClearance - 0.001),
        reason: 'a square window must not sit under the toolbar',
      );
      expect(rect.bottom, lessThanOrEqualTo(small.height - padding.bottom));
    });

    test('a window taller than the band is shrunk, not clipped', () {
      // Landscape-ish: shortest side 300 -> a 255 lp square, but only
      // 300 - (20 + 72) - (10 + 12) = 186 lp of vertical band to host it.
      const squat = Size(1024, 300);
      const padding = EdgeInsets.only(top: 20, bottom: 10);
      final rect = barcodeScanWindow(
        squat,
        padding,
        null,
        BarcodeWindowShape.square,
      );

      expect(rect.width, 255.0, reason: 'width is never shrunk');
      expect(rect.height, lessThan(255.0), reason: 'height gives way instead');
      expect(rect.height, closeTo(186.0, 0.001));
      expect(rect.top, greaterThanOrEqualTo(padding.top + kToolbarClearance));
      expect(rect.bottom, lessThanOrEqualTo(squat.height - padding.bottom));
    });

    test('a fitting window is left where the offset asked for it', () {
      final rect = barcodeScanWindow(
        _phone,
        _phonePadding,
        const Offset(0, -100),
        BarcodeWindowShape.square,
      );
      // top = 422 - 100 - 165.75 = 156.25, comfortably below 47 + 72 = 119.
      expect(rect.center.dy, closeTo(322.0, 0.001));
    });
  });

  group('resolvePosWindowOffset', () {
    test('centres a square window between the toolbar and the qty row', () {
      final height = barcodeWindowSize(
        _phone,
        BarcodeWindowShape.square,
      ).height;
      final offset = resolvePosWindowOffset(
        screenSize: _phone,
        viewPadding: _phonePadding,
        windowHeight: height,
        qtyButtonsBottomPadding: 230,
      );

      final rect = barcodeScanWindow(
        _phone,
        _phonePadding,
        offset,
        BarcodeWindowShape.square,
      );

      // Toolbar band starts at 47 + 72 = 119.
      expect(rect.top, greaterThan(_phonePadding.top + kToolbarClearance));
      // The qty row's top edge: 844 - (34 + 230) - ~47 row height.
      const qtyRowTop = 844 - (34 + 230) - 47;
      expect(
        rect.bottom,
        lessThan(qtyRowTop),
        reason: 'the window must clear the +/- quantity controls',
      );
    });

    test('falls back to the historic offset on a degenerate layout', () {
      // A qty padding large enough to erase the band entirely.
      final offset = resolvePosWindowOffset(
        screenSize: _phone,
        viewPadding: _phonePadding,
        windowHeight: 300,
        qtyButtonsBottomPadding: 900,
      );
      expect(offset, const Offset(0, -180));
    });
  });

  group('BarcodeScannerController', () {
    test('start() is a no-op when camera is already active', () async {
      final controller = BarcodeScannerController();
      bool toggleCalled = false;
      controller.attach(() async {
        toggleCalled = true;
      });

      // Manually set active state to true
      await controller.updateState(active: true, transitioning: false);
      expect(controller.isCameraActive, true);

      // Call start() - should be a no-op
      await controller.start();
      expect(toggleCalled, false);

      controller.dispose();
    });

    test('stop() is a no-op when camera is already stopped', () async {
      final controller = BarcodeScannerController();
      bool toggleCalled = false;
      controller.attach(() async {
        toggleCalled = true;
      });

      expect(controller.isCameraActive, false);

      // Call stop() - should be a no-op
      await controller.stop();
      expect(toggleCalled, false);

      controller.dispose();
    });

    test('toggle() is a no-op during transition', () async {
      final controller = BarcodeScannerController();
      bool toggleCalled = false;
      controller.attach(() async {
        toggleCalled = true;
      });

      // Start transition
      await controller.updateState(active: false, transitioning: true);
      expect(controller.isTransitioning, true);

      // Call toggle() - should be a no-op
      await controller.toggle();
      expect(toggleCalled, false);

      controller.dispose();
    });

    test('detach() resets cached hardware state', () async {
      final controller = BarcodeScannerController()..attach(() async {});

      await controller.updateState(active: true, transitioning: false);
      expect(controller.isCameraActive, true);

      // A controller reused across a remount must not report a camera that
      // no longer exists, or start() would no-op with "already active".
      controller.detach();
      expect(controller.isCameraActive, false);
      expect(controller.isTransitioning, false);

      controller.dispose();
    });

    test('detach() clears toggle callback', () async {
      bool toggleCalled = false;
      final controller = BarcodeScannerController()
        ..attach(() async {
          toggleCalled = true;
        })
        ..detach();

      // Call toggle() - should be a no-op because it's detached
      await controller.toggle();
      expect(toggleCalled, false);

      controller.dispose();
    });
  });
}
