# Camera Scanner Kit

A production-grade, highly optimized Flutter UI toolkit for barcode and QR scanning that solves camera lifecycle bugs and turns raw streams into fully-wired retail and warehouse workflows.

[![pub package](https://img.shields.io/pub/v/camera_scanner_kit.svg)](https://pub.dev/packages/camera_scanner_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Why Camera Scanner Kit?

While packages like `mobile_scanner` provide the raw camera stream, integrating them into a real-world app is notoriously error-prone. Developers constantly fight with native camera-lock hangs, "ghost scans" during exit animations, deactivated-widget context crashes, and lack of visual overlays. 

`camera_scanner_kit` wraps the raw scanner in an enterprise-ready shell featuring:
- **11-in-1 Routing Matrix**: Instantly launch single-scan, batch-accumulate, or streaming modes with customized barcode, QR, or manual overlays.
- **Static Image Decoding**: `scanImageFile()` reads a barcode out of a saved photo, screenshot or gallery pick — no camera, no scanner screen, no `BuildContext`.
- **Aimable Scan Windows**: `BarcodeWindowShape` offers `slim`, `tall` and `square` 1D windows, so hard-to-aim barcodes get a bigger target without ever widening detection to 2D codes.
- **Hardware-Safe Tripwires**: Failsafe hooks that guarantee the camera sensor is fully detached and released before screen transitions begin, ending "deactivated widget" crashes forever.
- **Built-in POS Mode**: A complete Point of Sale scanning interface featuring live quantity increment/decrement controls, ghost success pulses, and a reactive checkout cart summary.
- **Low-Latency Native Feedback**: Direct integration with native haptic and audio APIs for ultra-low latency scan confirmation beeps.
- **Collapsible Inline View**: An embeddable `BarcodeScannerView` that slides open/shut like a window blind and automatically sleeps during periods of inactivity.
- **Theme Isolation**: Hardened primitives and scoped Material 3 modals ensure the scanner UI remains visually consistent, rendering identically whether the host application uses Material 3 or legacy Material 2 configurations.

---

## Installation

Add `camera_scanner_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  camera_scanner_kit: ^2.0.0
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

### Upgrading from 1.2.0

`2.0.0` closes a dependency leak: restricting formats used to require adding
`mobile_scanner` to your own `pubspec.yaml`, even though this package promised
otherwise. Three changes, each a one-line fix:

1. **`allowedFormats` now takes `ScannerBarcodeFormat`.** Replace the `BarcodeFormat.`
   prefix with `ScannerBarcodeFormat.` — every value keeps its name.

   ```diff
   - allowedFormats: const [BarcodeFormat.ean13, BarcodeFormat.code128],
   + allowedFormats: const [ScannerBarcodeFormat.ean13, ScannerBarcodeFormat.code128],
   ```

   There is no `ScannerBarcodeFormat.all` or `.unknown` — use an empty list for
   "all", and see [Barcode Formats](#barcode-formats) for why.

2. **Drop `mobile_scanner` from your `pubspec.yaml`** if you added it only to name
   formats or lens types. You should no longer need it.

3. **`ScannerLensType.mobileScannerLens` was removed.** It was documented as
   internal but was publicly reachable. `ScannerLensType` itself is unchanged, so
   `lensType: ScannerLensType.wide` keeps working — only the getter is gone.

If you passed `offsetFromCenter` to `showPosBarcodeScanner`, nothing changes: it
became nullable so the POS screen can size its own window, and an explicit value
still wins.

---

## Sound & Haptics

Scan feedback is powered by [`native_haptics_and_audio`](https://pub.dev/packages/native_haptics_and_audio).
Every scanner — `ScannerScreen`, `BarcodeScannerView` and `PosBarcodeScannerScreen` —
initializes the shared audio engine on mount and preloads its beeps, so the first scan of a
session has no decode latency. Set `enableSoundAndVibration: false` to skip this entirely:
no engine is started and no audio is loaded.

### Configuring the audio engine

The audio engine is a **process-wide singleton**, and its configuration is honored from the
first successful `initialize()` call only. This package deliberately calls it with defaults
so it never silently clamps your app's settings.

If you want non-default behavior, call `initialize()` yourself in `main()` **before** any
scanner mounts:

```dart
import 'package:native_haptics_and_audio/native_haptics_and_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NativeHapticsAndAudioRepository.instance.initialize(
    // On iOS, beeps are silenced by the hardware ringer switch by default.
    // POS apps usually want them audible regardless:
    respectSilentSwitch: false,
  );

  runApp(const MyApp());
}
```

> **⚠️ iOS ringer switch.** Without the call above, `respectSilentSwitch` defaults to `true`
> and the scanner beep **will not play** when the device's mute switch is on. This is the
> most common cause of "the scanner stopped beeping" reports on iOS.

---

## Getting Started

### 1. Single Scan Mode
Open the camera, scan exactly one item, and automatically pop the screen to return the value.

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

Future<void> startSingleScan(BuildContext context) async {
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

class MyInlineForm extends StatefulWidget {
  const MyInlineForm({super.key});

  @override
  State<MyInlineForm> createState() => _MyInlineFormState();
}

class _MyInlineFormState extends State<MyInlineForm> {
  final _controller = BarcodeScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          onPressed: _controller.toggle,
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

> **💡 Programmatic Control:** In addition to `toggle()`, you can call `_controller.start()` and `_controller.stop()` for explicit, idempotent control. Both are safe to call repeatedly — calling `start()` on an already-active camera (or `stop()` on an already-stopped one) is a no-op.

> **Advanced Routing (GoRouter & Nested Navigators):** When using advanced routing packages like `GoRouter`, or when embedding the scanner inside a tab-based layout (like `IndexedStack` or `BottomNavigationBar`), you must be careful not to leave the camera hardware running when the user navigates away from the active tab. Leaving the camera active in the background will drain the user's battery and can cause native hardware crashes if another screen tries to claim the camera sensor. To see a complete, production-ready example of how to orchestrate the `BarcodeScannerView` with `GoRouter` and RouteAware mixins, check out our official **[Route Aware Sandbox](https://github.com/andresmontaniv/route_aware_sandbox/blob/main/lib/camera_scanner_screen.dart)** on GitHub.

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
| `showPosBarcodeScanner()` | POS | 1D Horizontal | `void` (fires `onScan`) |
| `showPosScanner()` | POS | Custom Rect (defaults to the 1D preset) | `void` (fires `onScan`) |

In each row the `*Custom` function is the primitive; the barcode and QR variants
are thin preset wrappers around it.

### Headless Functions — no camera, no `BuildContext`

These decode an image file the host app already has a path to. See
[Scanning from an Image File](#scanning-from-an-image-file).

| Function | Reads | Return Type |
|----------|-------|-------------|
| `scanImageFile()` | First code found | `Future<String?>` (`null` if none) |
| `scanImageFileAll()` | Every code found | `Future<List<String>>` (empty if none) |

> **Android and physical iOS devices only.** The iOS Simulator cannot analyze
> image files at all. On any unsupported platform both return empty and log the
> reason — they never throw.

---

## Scan Window Shape

The 1D barcode presets draw a wide, narrow strip — ideal for a well-aligned
retail barcode, but unforgiving if the user tilts the product. Pass a
`BarcodeWindowShape` to trade that precision for an easier target:

| Shape | Height | Use for |
|---|---|---|
| `BarcodeWindowShape.slim` | Fixed 130 lp (the default) | Trained operators, fastest decode |
| `BarcodeWindowShape.tall` | 60 % of the window width | A gentler target without a huge cut-out |
| `BarcodeWindowShape.square` | Equal to the window width (1:1) | Casual users, angled or awkward products |

The width is identical in all three (85 % of the shortest screen side, clamped
to 250–400 lp), and every shape stays fully responsive — the window is
recomputed on each build, so it survives rotation and split-screen.

```dart
// Drive it from a user preference — no Rect math, no format list, no extra
// dependency on `mobile_scanner`.
final shape = prefs.getBool('bigScanWindow') ?? false
    ? BarcodeWindowShape.square
    : BarcodeWindowShape.slim;

await scanBarcode(context, windowShape: shape);

showPosBarcodeScanner(
  context,
  windowShape: shape,
  onScan: (barcode, qty) => cart.addItem(barcode, quantity: qty),
);
```

> **This is a viewport setting, not a scan mode.** Format filtering is entirely
> independent of window geometry: `BarcodeWindowShape.square` renders a square
> window that still decodes *only* the standard horizontal 1D retail
> symbologies. To scan QR codes, use `scanQrCode()` / `ScannerViewConfig.qrCode`.

In POS mode the scan window, the +/− quantity row and the close button are laid
out from a single solved vertical budget, so they are guaranteed to clear one
another on every screen size. `square` therefore means *square where the budget
allows, and as tall as the budget allows otherwise* — on a very short screen it
may resolve to a 0.98 ratio rather than overlap the controls.

`qtyButtonsBottomPadding` is the quantity row's **preferred** position. It is
honoured exactly unless a taller scan window needs the space, in which case the
row slides down toward the close button. Pass an explicit `offsetFromCenter` to
place the window yourself and opt out of the solve.

If none of the presets fit, `scanCustom()` and `showPosScanner()` accept a
`ScannerViewConfig` with an arbitrary `Rect`. Note that a hand-built `Rect` is
fixed at construction — it will not track rotation or a resize, and you become
responsible for keeping it clear of the toolbar and any overlaid controls.

---

## Barcode Formats

Restricting a scanner to specific symbologies makes decoding faster and stops
the camera locking onto the wrong code when several are in frame. Pass an
`allowedFormats` list:

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

final code = await scanBarcode(
  context,
  allowedFormats: const [
    ScannerBarcodeFormat.ean13,
    ScannerBarcodeFormat.code128,
  ],
);
```

That import is the only one you need. **`ScannerBarcodeFormat` is owned by this
package**, so filtering formats never requires adding `mobile_scanner` to your
own `pubspec.yaml` — the enum you write is ours, and the translation to the
underlying engine happens internally.

`allowedFormats` is accepted by `scanBarcode()`, `scanBarcodeBatch()`,
`scanBarcodeStream()`, `showPosBarcodeScanner()`, `PosBarcodeScannerScreen` and
`ScannerViewConfig`.

**An empty list — the default — means "accept every format the device
supports."** That is the only way to express *all*: there is deliberately no
`ScannerBarcodeFormat.all`, because a list containing it alongside other entries
has no coherent meaning. There is likewise no `unknown` value, since that
identifies a decode result rather than something you can ask the camera to look
for.

Two rules worth knowing:

- The **1D presets** (`scanBarcode`, `ScannerViewConfig.barcode` and the POS
  screens) intersect whatever you pass against their built-in retail set, so a
  2D format supplied there is dropped rather than honoured. This is what
  guarantees a `square` window never starts reading QR codes. Use `scanQrCode()`
  or `ScannerViewConfig.qrCode` for 2D.
- `ScannerViewConfig.qrCode` locks the list to `ScannerBarcodeFormat.qrCode` and
  ignores anything you pass.

<details>
<summary>All supported formats</summary>

**1D:** `code128`, `code39`, `code93`, `codabar`, `ean13`, `ean8`, `upcA`,
`upcE`, `itf14`, `itf2of5`, `itf2of5WithChecksum`, `dataBar`,
`dataBarExpanded`, `dataBarLimited`

**2D:** `qrCode`, `microQrCode`, `dataMatrix`, `aztec`, `pdf417`, `maxiCode`

The 1D retail set used by the barcode presets is `code128`, `code39`, `code93`,
`ean13`, `ean8`, `upcA`, `upcE`, `itf14` and `codabar`.

</details>

---

## Scanning from an Image File

Sometimes the code isn't in front of the camera — it's a QR code the user already
saved, a screenshot, or a photo of a shelf label. `scanImageFile` decodes a file
the host app already has a path to, with no camera and no full-screen scanner.

Because `camera_scanner_kit` doesn't include gallery UI or permission handling,
picking the file is your app's job — use a package like
[`image_picker`](https://pub.dev/packages/image_picker) to get a path, then hand
it to `scanImageFile`:

```dart
import 'package:camera_scanner_kit/camera_scanner_kit.dart';
import 'package:image_picker/image_picker.dart';

Future<void> scanFromGallery() async {
  final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return;

  final String? code = await scanImageFile(image.path);

  if (code != null) {
    print('Found: $code');
  } else {
    print('No barcode found in image.');
  }
}
```

`image_picker` is the only extra dependency, and it is yours to choose — swap in
any file picker you prefer. Format filtering works exactly as it does for the
camera ([Barcode Formats](#barcode-formats)), and adds no dependency of its own:

```dart
final code = await scanImageFile(
  image.path,
  allowedFormats: const [ScannerBarcodeFormat.qrCode],
);
```

If the image might contain more than one code — a shelf photo, a screenshot with
several tickets — use `scanImageFileAll`, which returns every value found instead
of just the first:

```dart
final List<String> codes = await scanImageFileAll(image.path);
```

**Platform support: Android and physical iOS devices only.** The iOS Simulator
cannot analyze image files at all — this is a Simulator limitation, not a bug, so
test this feature on a real device. On an unsupported platform (Simulator, web,
desktop), both functions return `null` / `[]` rather than throwing, and log the
reason via `debugPrint`.

Neither function ever throws — a missing file, a corrupt image, or an
unsupported platform all resolve to "nothing found" rather than an exception.

---

## Orientation

**The full-screen scanners are designed for portrait.** Every default in this
package — the scan-window offsets, `qtyButtonsBottomPadding`, the close
button's bottom inset — is tuned for a portrait phone. This is a deliberate
scope decision: a cashier holds a phone upright, and a barcode is easiest to
aim at with the rear camera above the product.

**Landscape is supported as a guard, not as a headline feature.** If a device
rotates, the scanner keeps working and stays usable rather than degrading into
a squashed window:

* The `scan*` functions have no bottom chrome, so their window simply centres
  itself in the available height.
* `showPosBarcodeScanner` switches to a dedicated landscape layout. The +/−
  quantity controls become a **vertical rail on the right edge** and the close
  button moves to the **bottom-left corner** — one thumb per side. The toolbar
  stays where it is.

Because the toolbar's buttons hug the left and right screen edges while the
scan window stays horizontally centred, the two never collide, so the window is
free to use the full height of the screen. On a 891×411 dp landscape phone that
is a 331 lp tall window instead of the 71 lp a naive vertical stack would leave.

> `BarcodeWindowShape` still applies in landscape, but the shorter axis can
> constrain it: `square` resolves to a true 1:1 on most screens and to about
> 0.95 on a 891×411 phone, where the available height runs out first.

**Locking orientation is the host app's job, not the package's.** Flutter's
`SystemChrome.setPreferredOrientations` is app-global and has no getter, so a
package that locked portrait on push could not know what to restore on pop —
it would silently clobber an app that had deliberately locked itself. If you
want the scanner pinned to portrait, do it in your own app:

```dart
await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
await scanBarcode(context);
await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
```

> On iPad this is ignored unless the app disables multitasking
> (“Requires full screen” in Xcode).

The **inline** `BarcodeScannerView` is unaffected by any of this. It is a
bounded box sized from its own width, not the screen height, so it reflows with
its parent in either orientation.

---

## License

This package is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
