# Camera Scanner Kit

A private, production-ready Flutter UI toolkit for barcode and QR scanning, built on [`mobile_scanner`](https://pub.dev/packages/mobile_scanner). Features **9 routing modes**, customizable toolbars, and a built-in POS interface.

---

## Installation (Git Dependency)

This package is distributed as a private Git dependency. Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  camera_scanner_kit:
    git:
      url: https://github.com/AndresMontaniv/flutter_camera_scanner_kit.git
```

Then run:

```bash
flutter pub get
```

### Platform Setup

| Platform | Required |
|----------|----------|
| **Android** | Add `<uses-permission android:name="android.permission.CAMERA" />` in `AndroidManifest.xml` |
| **iOS** | Add `NSCameraUsageDescription` to `Info.plist` |

---

## Quick Start

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

// POS mode — scan barcodes with quantity controls
showPosBarcodeScanner(
  context,
  onScan: (barcode, qty) {
    print('Scanned $barcode × $qty');
  },
);

// Single scan — returns the scanned value
final result = await scanBarcode(context);

// Stream mode — real-time callback
await scanBarcodeStream(
  context,
  onCameraScan: (barcode) => print(barcode),
);
```

---

## Public API

### Widgets

| Widget | Description |
|--------|-------------|
| `ScannerScreen.singleScan()` | Reads exactly one barcode and pops with the result |
| `ScannerScreen.multiscan()` | Accumulates multiple scans; supports batch + stream routing |
| `PosBarcodeScannerScreen` | Full POS interface with quantity increment/decrement controls |

### Facade Functions (`functions.dart`)

**Single Scan** — pops with a `String?`:

| Function | Overlay |
|----------|---------|
| `scanCustom()` | Custom / manual `Rect` |
| `scanBarcode()` | Horizontal 1D strip |
| `scanQrCode()` | 1:1 square for 2D codes |

**Batch Pop** — pops with a `List<String>?`:

| Function | Overlay |
|----------|---------|
| `scanCustomBatch()` | Custom |
| `scanBarcodeBatch()` | Horizontal 1D strip |
| `scanQrCodeBatch()` | 1:1 square |

**Stream** — fires `onCameraScan` in real-time:

| Function | Overlay |
|----------|---------|
| `scanCustomStream()` | Custom |
| `scanBarcodeStream()` | Horizontal 1D strip |
| `scanQrCodeStream()` | 1:1 square |

**POS:**

| Function | Description |
|----------|-------------|
| `showPosBarcodeScanner()` | Launches the POS screen with quantity buttons |

### Configuration Classes

| Class | Purpose |
|-------|---------|
| `ScannerViewConfig` | Scan window shape, overlay style, allowed formats |
| `StandardToolBar` | Close, flash, camera-switch buttons |
| `BatchToolBar` | Extends `StandardToolBar` with a scanned-items cart button |
| `CustomToolBar` | Full custom toolbar via builder callback |
| `ScannerOverlayStyle` | Border color, width, radius, and background opacity |
