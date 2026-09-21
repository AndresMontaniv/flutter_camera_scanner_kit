# camera_scanner_kit example

A single-screen demo app that exercises the package's routing matrix against a
real camera.

## What it covers

- **Every routing mode** — single scan, batch accumulation and streaming, across
  the custom, barcode and QR overlays.
- **POS mode** — `showPosBarcodeScanner` with its quantity controls, so you can
  see the cart badge and the +/− rail behave on your own device.
- **Scan window shapes** — a dropdown switches `BarcodeWindowShape` between
  `slim`, `tall` and `square`, which is the quickest way to see how each one
  resolves on a given screen size.
- **Format filtering** — `ScannerBarcodeFormat` lists are passed straight
  through. Note that `pubspec.yaml` here depends on nothing but
  `camera_scanner_kit`, which is the point: restricting formats needs no
  `mobile_scanner` dependency.
- **Inline mode** — `inline_scanner_example.dart` embeds a `BarcodeScannerView`
  in an ordinary page and drives it with an external controller.

## Running it

```bash
cd example
flutter run
```

Use a **physical device**. The iOS Simulator has no camera, and it also cannot
analyze image files, so neither the live scanner nor `scanImageFile` will work
there.

Rotate the device while the POS screen is open to see the dedicated landscape
layout described in the main README's *Orientation* section.
