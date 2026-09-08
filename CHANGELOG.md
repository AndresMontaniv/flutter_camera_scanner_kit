## [Unreleased]

* **Feature (Scan Window):** Added `BarcodeWindowShape` — `standard`, `tall` and `square` — exposed as a `windowShape` parameter on `scanBarcode`, `scanBarcodeBatch`, `scanBarcodeStream`, `showPosBarcodeScanner`, `PosBarcodeScannerScreen` and `ScannerViewConfig.barcode`. It lets an app offer a larger, easier-to-aim 1D scan window without hand-building a `Rect`. **Geometry only:** the window still decodes exclusively the standard horizontal 1D retail symbologies, so `BarcodeWindowShape.square` never starts reading QR codes. The window's width is unchanged in every shape.
* **Feature (POS):** Added `showPosScanner()`, the unopinionated POS primitive taking a `ScannerViewConfig?`. `showPosBarcodeScanner()` is now a thin wrapper around it that builds `ScannerViewConfig.barcode(...)`, mirroring how `scanBarcode` delegates to `scanCustom`. `PosBarcodeScannerScreen` gained a matching `scannerViewConfig` parameter. When a custom config is supplied it is used verbatim and `overlayStyle`, `offsetFromCenter`, `allowedFormats` and `windowShape` are ignored.
* **Feature (POS):** The POS scan window is now fitted automatically between the toolbar and the +/− quantity row when `windowShape` is `tall` or `square`, so a larger window cannot overlap the controls on any screen size.
* **Fix (POS):** `PosBarcodeScannerScreen`'s scan-list badge now takes its border tint from whichever `ScannerOverlayStyle` actually reaches the overlay, so a custom `scannerViewConfig` no longer leaves the badge on the default blue.
* **Docs:** Corrected `PosBarcodeScannerScreen.offsetFromCenter`'s dartdoc, which claimed it fell back to the barcode preset's `Offset(0, -80)` when the facade in fact applied `Offset(0, -180)`.
* **Test:** Added unit coverage for the scan-window geometry, including a regression lock asserting that `BarcodeWindowShape.standard` reproduces the historic 1.2.0 rect exactly.

> **Upgrade note:** `showPosBarcodeScanner`'s `offsetFromCenter` changed from `Offset offsetFromCenter = const Offset(0, -180)` to `Offset? offsetFromCenter` (default `null`), which is what lets the screen fit the window to the chosen shape. This is source-compatible: passing a value behaves as before, and passing nothing still resolves to `Offset(0, -180)` for the default `standard` shape. The default POS and barcode screens are unchanged.
>
> Note also that `standard` deliberately keeps its historic geometry *without* the new vertical fit. On very short screens the default POS offset can already tuck the window slightly under the toolbar; that pre-existing behavior is preserved rather than silently corrected, so upgrading changes nothing visually. Switch to `tall` or `square` to get the fitted placement.

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
