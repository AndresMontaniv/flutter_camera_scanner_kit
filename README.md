# Camera Scanner Kit

A production-grade, highly optimized Flutter UI toolkit for barcode and QR scanning that solves camera lifecycle bugs and turns raw streams into fully-wired retail and warehouse workflows.

[![pub package](https://img.shields.io/pub/v/camera_scanner_kit.svg)](https://pub.dev/packages/camera_scanner_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Why Camera Scanner Kit?

While packages like `mobile_scanner` provide the raw camera stream, integrating them into a real-world app is notoriously error-prone. Developers constantly fight with native camera-lock hangs, "ghost scans" during exit animations, deactivated-widget context crashes, and lack of visual overlays. 

`camera_scanner_kit` wraps the raw scanner in an enterprise-ready shell featuring:
- **9-in-1 Routing Matrix**: Instantly launch single-scan, batch-accumulate, or streaming modes with customized barcode, QR, or manual overlays.
- **Hardware-Safe Tripwires**: Failsafe hooks that guarantee the camera sensor is fully detached and released before screen transitions begin, ending "deactivated widget" crashes forever.
- **Built-in POS Mode**: A complete Point of Sale scanning interface featuring live quantity increment/decrement controls, ghost success pulses, and a reactive checkout cart summary.
- **Low-Latency Native Feedback**: Direct integration with native haptic and audio APIs for ultra-low latency scan confirmation beeps.
- **Collapsible Inline View**: An embeddable `BarcodeScannerView` that slides open/shut like a window blind and automatically sleeps during periods of inactivity.

---

## Installation

Add `camera_scanner_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  camera_scanner_kit: ^1.0.2
```

### Platform Setup

#### Android
Add the camera permission to your `AndroidManifest.xml` (usually under `android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS
Add the camera usage description to your `Info.plist` (usually under `ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan barcodes.</string>
```

---

## Getting Started

### 1. Single Scan Mode
Open the camera, scan exactly one item, and automatically pop the screen to return the value.

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

void startSingleScan(BuildContext context) async {
  // scanBarcode is optimized with a wide horizontal 1D cutout
  final String? barcode = await scanBarcode(context);
  
  if (barcode != null) {
    print('Scanned barcode: $barcode');
  }
}
```

### 2. POS Mode (With Quantity Controls)
Launch a full retail checkout scanner with quantity adjustment controls (+/-) and a live cart preview sheet.

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

void openCheckout(BuildContext context) {
  showPosBarcodeScanner(
    context,
    onScan: (barcode, quantity) {
      print('Adding $quantity of $barcode to checkout cart');
    },
  );
}
```

### 3. Inline Mode (Embeddable Widget)
Embed a scanning window directly inside your existing UI (e.g. form fields or lists). Includes a smooth expand/collapse transition.

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

class MyInlineForm extends StatelessWidget {
  final BarcodeScannerController _controller = BarcodeScannerController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BarcodeScannerView(
          controller: _controller,
          onBarcodeScanned: (barcode) {
            print('Inline scan: $barcode');
          },
        ),
        ElevatedButton(
          onPressed: () => _controller.toggle(),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Text(_controller.isCameraActive ? 'Close Scanner' : 'Open Scanner');
            },
          ),
        ),
      ],
    );
  }
}
```

> **💡 Programmatic Control (v1.0.2+):** In addition to `toggle()`, you can call `_controller.start()` and `_controller.stop()` for explicit, idempotent control. Both are safe to call repeatedly — calling `start()` on an already-active camera (or `stop()` on an already-stopped one) is a no-op.

---

## API Reference

### Facade Functions (`functions.dart`)

| Function | Mode | Overlay Shape | Return Type |
|----------|------|---------------|-------------|
| `scanBarcode()` | Single | 1D Horizontal | `Future<String?>` |
| `scanQrCode()` | Single | 1:1 Square | `Future<String?>` |
| `scanCustom()` | Single | Custom Rect | `Future<String?>` |
| `scanBarcodeBatch()` | Batch | 1D Horizontal | `Future<List<String>?>` |
| `scanQrCodeBatch()` | Batch | 1:1 Square | `Future<List<String>?>` |
| `scanCustomBatch()` | Batch | Custom Rect | `Future<List<String>?>` |
| `scanBarcodeStream()` | Stream | 1D Horizontal | `Future<void>` (fires `onCameraScan`) |
| `scanQrCodeStream()` | Stream | 1:1 Square | `Future<void>` (fires `onCameraScan`) |
| `scanCustomStream()` | Stream | Custom Rect | `Future<void>` (fires `onCameraScan`) |

---

## License

This package is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
