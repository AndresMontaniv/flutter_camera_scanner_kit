import 'package:flutter_test/flutter_test.dart';

import 'package:camera_scanner_kit/camera_scanner_kit.dart';

void main() {
  test('ScannerOverlayStyle defaults are set correctly', () {
    const style = ScannerOverlayStyle();
    expect(style.opacity, 0.5);
    expect(style.borderWidth, 2.5);
    expect(style.borderRadius, 12.0);
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
