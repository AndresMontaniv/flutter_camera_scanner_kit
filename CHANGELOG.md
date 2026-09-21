## 2.0.0

### Breaking

* **`allowedFormats` now takes `List<ScannerBarcodeFormat>`** instead of `mobile_scanner`'s `List<BarcodeFormat>` — on `scanBarcode`, `scanBarcodeBatch`, `scanBarcodeStream`, `showPosBarcodeScanner`, `PosBarcodeScannerScreen` and `ScannerViewConfig`. Restricting formats previously forced a direct `mobile_scanner` dependency, contradicting the README's claim that none was needed.
  **Migration:** replace `BarcodeFormat.` with `ScannerBarcodeFormat.` — the values carry the same names — and drop `mobile_scanner` from your `pubspec.yaml` if you added it only for this.
* `ScannerBarcodeFormat` covers all 20 real symbologies, but omits `unknown` and `all` (the first identifies a decode *result*; the second is already expressed by an empty allow-list) along with the deprecated `itf` and `codebar` aliases.
* **Removed `ScannerLensType.mobileScannerLens`.** It returned `mobile_scanner`'s `CameraLensType` despite being documented as internal, and is now a package-private mapper. `ScannerLensType` itself is unchanged.
* **Removed `assertMsg`**, an internal string a `part` directive had made public by accident. It was never referenced anywhere in the package.
* `showPosBarcodeScanner`'s `offsetFromCenter` is now `Offset?` (default `null`), which lets the screen fit the window to the chosen shape. Passing a value behaves as before; passing nothing resolves to the previous `Offset(0, -180)` for the default `slim` shape.

### Added

* **Static image decoding.** `scanImageFile(filePath)` returns the first code found in an existing image — a saved QR code, a screenshot, a photo of a shelf label — and `scanImageFileAll(filePath)` returns every code found. Both accept `allowedFormats`, and need no camera, no scanner screen and no `BuildContext`. Picking the file stays the host app's job; the README's *Scanning from an Image File* section has an `image_picker` recipe.
  **Android and physical iOS devices only** — a limitation of the underlying ML Kit/Vision analysis; the iOS Simulator cannot analyze image files at all. Elsewhere both return `null` / `[]` and log why, and never throw.
* **`BarcodeWindowShape`** — `slim`, `tall` and `square` — a `windowShape` parameter on every barcode entry point and on `ScannerViewConfig.barcode`, for a larger, easier-to-aim 1D window without hand-building a `Rect`. **Geometry only:** all three shapes decode exclusively the 1D retail symbologies, so `square` never starts reading QR codes, and the width is identical in each.
* **`showPosScanner()`** — the unopinionated POS primitive taking a `ScannerViewConfig?`, mirroring how `scanCustom` sits behind `scanBarcode`. `PosBarcodeScannerScreen` gained a matching `scannerViewConfig`. When one is supplied the caller owns the geometry, and `overlayStyle`, `offsetFromCenter`, `allowedFormats` and `windowShape` are ignored.
* `ScannerViewConfig.barcode` now accepts an explicit `scanWindow`, keeping the 1D format filter for screens that solve their own layout.

### Fixed

* **A 1D scanner could silently widen to every format.** In barcode mode the allow-list is intersected against the 1D retail set; an all-2D list left that intersection empty, and an empty list reaches `MobileScannerController` as *"detect every supported format"*. So `scanBarcode(allowedFormats: [ScannerBarcodeFormat.qrCode])` decoded everything rather than nothing. It now falls back to the full 1D set.
* **The POS screen solves its portrait layout** instead of positioning the scan window and quantity row against independent hardcoded offsets. With `square` the two could overlap on smaller phones, and the default window sat partly under the toolbar there. All three elements now get 16 lp of clearance on every screen size; geometry is unchanged on every device where 1.2.0 was already correct.
* **The POS screen has a dedicated landscape layout.** Chrome previously ate 340 of 411 lp on an 891×411 dp screen, squeezing the window to a 71 lp strip. The quantity controls now become a right-edge rail and the close button moves to the bottom-left, leaving the window 331 lp on the same device. Long `closeButtonLabel`s are capped and ellipsised so they cannot reach the window. Portrait is untouched.
* `qtyButtonsBottomPadding` is now the quantity row's **preferred** position — honoured exactly unless a taller window needs the space, in which case the row slides toward the close button.
* The scan-list badge takes its border tint from whichever `ScannerOverlayStyle` reaches the overlay, so a custom `scannerViewConfig` no longer leaves it on the default blue.
* Corrected `PosBarcodeScannerScreen.offsetFromCenter`'s dartdoc, which named the wrong default.

### Dependencies

* Upgraded `mobile_scanner` from `^7.4.0` to `^7.4.2`.

### Docs & tests

* README gained **Upgrading from 1.2.0** and **Orientation** sections, and the static-image API is now in the reference tables.
* Log lines use a single `[CameraScannerKit]` tag; thirteen had drifted to `[camera_scanner_kit]`.
* Format filtering moved into a unit-tested `resolveEffectiveFormats` — the 1D intersection rule previously had no coverage. Added scan-window and POS-solver geometry tests across 7-device portrait and landscape matrices, plus a regression lock on the unchanged portrait geometry.

## 1.2.0

* **Dependency:** Upgraded `native_haptics_and_audio` to `^2.0.0`. If your app also depends on it directly, bump your own constraint to `^2.0.0` — otherwise this release will not resolve.
* **Fix (Audio):** The scanner beep is now preloaded and pinned at startup. 2.0.0 changed `initialize()` to load no audio, so the first scan of a session would otherwise decode its beep on the hot path, losing the zero-latency guarantee.
* **Fix (Audio):** Scan feedback is no longer dropped when a barcode is read before the audio engine finishes initializing. Playback now defers onto the warm-up instead of silently no-opping.
* **Fix (Inline Scanner):** `BarcodeScannerView` now detaches its `BarcodeScannerController` in `dispose()`, and rebinds a swapped controller via `didUpdateWidget`. Previously a controller that outlived the view threw `setState() called after dispose()` on a later `start()`, `stop()` or `toggle()`.
* **Fix (ScannerScreen):** The same-item cooldown now uses a monotonic `Stopwatch` instead of `DateTime.now()`, so an NTP sync or a device time/timezone change can no longer freeze or skip it.
* **Perf:** `enableSoundAndVibration: false` no longer initializes the native audio engine or loads any audio. Note this value is read once in `initState`; changing it at runtime requires a remount.
* **Documentation:** Added a **Sound & Haptics** section to the README covering the shared audio engine and `respectSilentSwitch` — which the host app must set in `main()` for scanner beeps to survive the iOS hardware ringer switch. Also repaired several broken DartDoc references.
* **Chore:** Migrated to the 2.0.0 API (`PosSound` → `NativeSound`, `PosHaptic` → `HapticPattern`, `playSound()` → `play()`) and modernized `analysis_options.yaml` for Dart 3.11.
* **Chore:** Corrected the Flutter constraint from `>=1.17.0` to `>=3.41.0`. The old bound was unenforceable — the Dart constraint already required Flutter 3.41 — so this excludes no one who could install 1.1.6.

## 1.1.6

* **Dependency:** Upgraded `native_haptics_and_audio` to `^1.1.0` to inherit its new SwiftPM iOS architecture, Android Built-in Kotlin compatibility, and hardened `initialize()` concurrency guards.
* **Dependency:** Upgraded `mobile_scanner` to `^7.4.0`.
* **Fix:** Wrapped `_effects.initialize()` calls in `unawaited()` to satisfy `unawaited_futures` linting on the new async signature.

## 1.1.5

* **Fix:** Added `isTransitioning` idempotency guards to `start()` and `stop()` in `BarcodeScannerController` to prevent redundant hardware toggle attempts during active transitions.
* **Feature:** Exposed `detach()` on `BarcodeScannerController` to safely release the hardware bindings without fully disposing the controller, useful for complex tab-switching rebuilds.
* **Fix:** Corrected an inconsistent logging tag in `BarcodeScannerView` for background lifecycle events.
* **Test:** Added unit tests covering the idempotency guarantees of the `BarcodeScannerController`.
* **Documentation:** Clarified the safe programmatic pop architecture in `PosBarcodeScannerScreen`.

## 1.1.4
* **Fix:** Resolved an async disposal race condition in `BarcodeScannerController` where `notifyListeners()` could fire after `dispose()` if the parent widget was torn down during the UX transition padding delay. The controller now tracks its own disposal state and silently drops stale callbacks.

## 1.1.3

* **Refactor (Lifecycle Management):** Migrated `BarcodeScannerView` lifecycle handling from `WidgetsBindingObserver` to Flutter's modern `AppLifecycleListener` API, improving listener disposal and memory safety.
* **Feature (Inline Scanner):** Added `stopCameraOnBackground` parameter (defaults to `true`) to `BarcodeScannerView`, giving developers granular control over automatic camera hardware teardown when the application transitions to background states.


## 1.1.2

* **UI (Theme Isolation):** Refactored internal action buttons to use primitive `Material` and `InkWell` widgets, isolating them from legacy global `useMaterial3: false` theme overrides in host applications.
* **UI (Modals):** Scoped all modal bottom sheets (like the Scanned Items list) inside a clean Material 3 `Theme` widget to ensure perfect typography, colors, and border rendering regardless of the parent app's legacy theme matrix.
* **Fix:** Resolved a runtime `Material` `AssertionError` crash caused by conflicting `type` and `shape` parameters on circular buttons.

## 1.1.1

* **Fix:** Resolved a "zombie stream" deadlock where the barcode `EventChannel` would silently fail to receive frames after the device was locked and unlocked.
* **Fix (ScannerScreen):** Implemented a 250ms hardware release delay on `AppLifecycleState.resumed` to prevent native camera lockups, securely guarded by the `_isPopping` tripwire.
* **UX (Inline Scanner):** The `BarcodeScannerView` now automatically closes its UI and safely detaches from the sensor when the app goes to the background, improving user privacy and preventing battery drain.

## 1.1.0

* **Feature:** Added `ScannerLensType` enum to provide hardware-level control over the physical camera lens. Prevents autofocus "jumping" on iOS Pro models by allowing developers to lock the ultra-wide lens.
* **Feature:** Exposed the `initialZoom` parameter across all scanner entry points. Defaulted to `null` to respect native OS behaviors.
* **Refactor:** Completely restructured internal package architecture into strict domain folders (`inline_scanner`, `scanner_screen`, `prebuilt_screens`, and `widgets`).
* **Documentation:** Added comprehensive, production-grade DartDocs to all public APIs, detailing hardware fragmentation warnings and architecture requirements.

## 1.0.2

* **Feature:** Added idempotent `start()` and `stop()` methods to `BarcodeScannerController` for safer programmatic lifecycle control.
* **Fix:** Resolved a microtask collision and debug-mode breakpoint caused by OS Camera Permission dialogs interrupting the camera boot sequence.
* **UI Refactor:** Generalized `BarcodeScannerView`. Replaced hardcoded UI constraints by exposing `borderRadius`, removing redundant clipping masks, and enforcing compositional padding.
* **Polish:** Upgraded internal logs to strict enterprise format and improved public API DartDocs.

## 1.0.1
* Fix pub.dev description length warning to improve search engine SEO and package scoring.

# 1.0.0

- **Initial Stable Release** of `camera_scanner_kit`.
- **9-in-1 Routing Matrix**: Modular API providing 9 scanning combinations (Single Scan, Batch accumulation, and real-time Stream routing across Custom, Barcode, and QR Code views).
- **POS Mode**: Dedicated `PosBarcodeScannerScreen` featuring built-in quantity adjustment controls (+/-), success/error haptic feedback, and a reactive badge showing scanned item summaries in a sheet.
- **Inline Mode**: Embeddable, inline `BarcodeScannerView` with smooth collapsible window blind animations, flashlight toggles, and automatic teardown on inactivity timeout.
- **Teardown & Lifecycle Protection**: Hardware-safe tripwire system to prevent deactivated-widget crashes, ghost scans, and camera locks across Android and iOS lifecycle transitions.

## 0.0.0
- **Internal Alpha Release.**
- Extracted core scanning logic into a modular package architecture.
- Implemented 9-in-1 routing matrix (Single, Batch, Stream, etc.).
- Added `PosBarcodeScannerScreen` with quantity increment/decrement controls.
- Standardized UI components (Overlays, Connected Toolbars, Error Widgets).
- Prepended library logs with `[CameraScannerKit]` for easier debugging.
