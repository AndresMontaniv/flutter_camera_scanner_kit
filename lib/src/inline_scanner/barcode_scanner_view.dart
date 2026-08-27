import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:native_haptics_and_audio/native_haptics_and_audio.dart';

import '../widgets/action_button.dart';
import '../scanner_lens_type.dart';
import 'barcode_scanner_controller.dart';

const assetMessage = 'BarcodeScannerView: maxWidth must be between 200.0 and 600.0 to ensure scanning performance.';

/// An embeddable, inline barcode scanner widget that can be placed anywhere
/// in the widget tree — forms, detail pages, inventory screens, etc.
///
/// Unlike the full-screen [ScannerScreen], this widget renders as a compact,
/// self-contained camera window with an animated "window blind" open/close
/// transition. It manages its own camera lifecycle, idle timeout, and
/// same-item cooldown logic.
///
/// ### Architecture
///
/// The camera hardware is toggled via the built-in Start/Stop button (when
/// [showToggleButton] is `true`) **or** programmatically through an external
/// [BarcodeScannerController]. The controller exposes [BarcodeScannerController.start],
/// [BarcodeScannerController.stop], and [BarcodeScannerController.toggle] for
/// full external control, plus observable [BarcodeScannerController.isCameraActive]
/// and [BarcodeScannerController.isTransitioning] state properties.
///
/// > ### ⚠️ Singleton Trap — IndexedStack & Bottom Navigation
/// >
/// > **Do NOT place this widget inside an [IndexedStack], [Offstage], or a
/// > tab-based bottom navigation layout that keeps hidden tabs alive.**
/// >
/// > When a tab is hidden but still mounted, the native camera hardware
/// > remains allocated. This causes:
/// >
/// > 1. **Battery drain** — the camera pipeline runs even when invisible.
/// > 2. **Hardware collisions** — switching to another tab that also opens a
/// >    camera will fail because the device sensor is already locked.
/// > 3. **Platform crashes** — some Android OEMs throw native exceptions
/// >    when two camera clients compete for the same sensor.
/// >
/// > **Solution:** Always **unmount** this widget when the tab is hidden.
/// > Use [BarcodeScannerController.stop] before hiding, or wrap the tab
/// > content in a builder that only mounts the scanner when the tab is
/// > visible:
/// >
/// > ```dart
/// > // ✅ SAFE — scanner is unmounted when tab is hidden
/// > IndexedStack(
/// >   index: _currentIndex,
/// >   children: [
/// >     HomeTab(),
/// >     if (_currentIndex == 1) ScannerTab() else const SizedBox.shrink(),
/// >   ],
/// > )
/// > ```
///
/// ### Parameters
///
/// * [onBarcodeScanned] — **Required.** Fires with the decoded barcode `String`
///   each time a scan is accepted.
/// * [maxWidth] — Maximum width constraint for the camera window. Must be
///   between `200.0` and `600.0` (inclusive). Values outside this range will
///   trigger an [AssertionError] in debug mode. Defaults to `400.0`.
/// * [enableSoundAndVibration] — Whether to trigger haptic feedback and an
///   audible beep on a successful scan. Defaults to `true`.
/// * [sameItemCooldownMs] — Minimum milliseconds before the same barcode
///   value is accepted again. Prevents rapid-fire duplicates when the user
///   holds a barcode under the camera. Defaults to `1500`.
/// * [idleTimeout] — Duration of inactivity after which the camera
///   automatically shuts down to conserve battery. Defaults to 90 seconds.
/// * [controller] — Optional external [BarcodeScannerController] for
///   programmatic start/stop and state observation.
/// * [showToggleButton] — Whether to display the built-in Start/Stop toggle
///   button below the camera window. Defaults to `true`.
/// * [useDarkModeButtonTheme] — When `true`, overlay buttons (close,
///   flashlight) use dark translucent backgrounds. Defaults to `true`.
/// * [borderRadius] — Corner radius for the camera window clip. Defaults to
///   `BorderRadius.all(Radius.circular(12))`.
/// * [lensType] — The physical camera lens to activate. Defaults to
///   [ScannerLensType.any] for maximum device compatibility. See
///   [ScannerLensType] for hardware fragmentation warnings.
/// * [initialZoom] — The initial zoom scale for the camera (0.0 – 1.0).
///   Only supported on iOS, macOS, and Android. Defaults to `null` (no zoom).
/// * [stopCameraOnBackground] — Whether to automatically stop the camera
///   when the app transitions to background states. Defaults to `true`.
///
/// ### Example
/// ```dart
/// final controller = BarcodeScannerController();
///
/// BarcodeScannerView(
///   controller: controller,
///   maxWidth: 350,
///   sameItemCooldownMs: 2000,
///   onBarcodeScanned: (barcode) {
///     setState(() => _lastScanned = barcode);
///   },
/// )
///
/// // Programmatically start the camera from an external button:
/// ElevatedButton(
///   onPressed: controller.start,
///   child: const Text('Open Scanner'),
/// )
/// ```
class BarcodeScannerView extends StatefulWidget {
  /// Maximum width constraint for the camera window.
  ///
  /// **Asserts** that the value is between `200.0` and `600.0` (inclusive)
  /// to ensure adequate scanning resolution while preventing the camera
  /// feed from consuming excessive screen real estate.
  final double maxWidth;

  /// Called with the decoded barcode `String` each time a scan is accepted.
  final void Function(String barcode) onBarcodeScanned;

  /// Whether haptic vibration and audible beep are triggered on success.
  final bool enableSoundAndVibration;

  /// Minimum milliseconds before the same barcode value is accepted again.
  final int sameItemCooldownMs;

  /// Inactivity timeout after which the camera auto-shuts down.
  final Duration idleTimeout;

  /// Optional external controller for programmatic start/stop and state
  /// observation. See [BarcodeScannerController].
  final BarcodeScannerController? controller;

  /// Whether to display the built-in Start/Stop toggle button.
  final bool showToggleButton;

  /// When `true`, overlay buttons use dark translucent backgrounds.
  final bool useDarkModeButtonTheme;

  /// Corner radius for the camera window clip.
  final BorderRadiusGeometry borderRadius;

  /// The physical camera lens to use. Defaults to [ScannerLensType.any].
  /// See [ScannerLensType] for hardware fragmentation warnings.
  final ScannerLensType lensType;

  /// The initial zoom scale for the camera (0.0 – 1.0).
  /// Only supported on iOS, macOS, and Android. Defaults to `null`.
  final double? initialZoom;

  /// Whether to automatically stop the camera when the app transitions to
  /// background states (`inactive`, `paused`, `detached`, `hidden`).
  ///
  /// Defaults to `true`. Disabling this means the camera hardware will
  /// remain active while the app is in the background, which **will cause
  /// battery drain** and may trigger platform-level hardware lock errors
  /// if another app attempts to access the camera sensor.
  ///
  /// **This value is read once during [State.initState] and is not
  /// re-evaluated on subsequent rebuilds.** To change lifecycle behavior
  /// at runtime, assign a new [Key] (e.g., `ValueKey(stopCameraOnBackground)`)
  /// to force a full widget unmount and remount.
  final bool stopCameraOnBackground;

  /// Creates a [BarcodeScannerView].
  ///
  /// Throws an [AssertionError] in debug mode if [maxWidth] is outside the
  /// `200.0`–`600.0` range.
  const BarcodeScannerView({
    super.key,
    required this.onBarcodeScanned,
    this.maxWidth = 400.0,
    this.enableSoundAndVibration = true,
    this.sameItemCooldownMs = 1500,
    this.idleTimeout = const Duration(seconds: 90),
    this.controller,
    this.showToggleButton = true,
    this.useDarkModeButtonTheme = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.lensType = ScannerLensType.any,
    this.initialZoom,
    this.stopCameraOnBackground = true,
  }) : assert(maxWidth >= 200.0 && maxWidth <= 600.0, assetMessage);

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  AppLifecycleListener? _lifecycleListener;
  late final MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  Timer? _idleTimer;

  bool _isCameraActive = false;
  bool _isTransitioning = false;
  String? _lastScannedCode;
  final Stopwatch _cooldownWatch = Stopwatch();

  final _effects = NativeHapticsAndAudioRepository.instance;

  // Preloads only scannerBeep — this widget never plays warningBeep, so
  // pinning it here would hold RAM for a sound it never uses.
  Future<void> _warmUpEffects() async {
    if (!widget.enableSoundAndVibration) return;
    await _effects.initialize();
    if (!await _effects.preload(NativeSound.scannerBeep)) {
      debugPrint('[camera_scanner_kit] BarcodeScannerView: beep failed to preload.');
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      facing: CameraFacing.back,
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      lensType: widget.lensType.mobileScannerLens,
      initialZoom: widget.initialZoom,
    );
    if (widget.stopCameraOnBackground) {
      _lifecycleListener = AppLifecycleListener(
        onInactive: _onAppBackgrounded,
        onPause: _onAppBackgrounded,
        onDetach: _onAppBackgrounded,
        onHide: _onAppBackgrounded,
      );
    }
    unawaited(_warmUpEffects());
    _subscription = _controller.barcodes.listen(_onBarcodeDetected);
    widget.controller?.attach(_toggleCamera);
  }

  void _onAppBackgrounded() {
    if (!_isCameraActive) return;
    debugPrint('[camera_scanner_kit] BarcodeScannerView: App backgrounded — auto-stopping camera.');
    _cancelIdleTimer();
    unawaited(_controller.stop());
    setState(() => _isCameraActive = false);
    widget.controller?.updateState(active: false, transitioning: false);
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
  }

  void _resetIdleTimer() {
    _cancelIdleTimer();
    if (_isCameraActive) {
      _idleTimer = Timer(widget.idleTimeout, _toggleCamera);
    }
  }

  static const _animationDuration = Duration(milliseconds: 300);

  // Pre-compiled button styles (Finding #7 — avoid allocation on every rebuild)
  static final _activeToggleStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade700,
    foregroundColor: Colors.white,
  );
  static final _inactiveToggleStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue.shade700,
    foregroundColor: Colors.white,
  );

  Future<void> _toggleCamera() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    widget.controller?.updateState(
      active: _isCameraActive,
      transitioning: true,
    );

    if (_isCameraActive) {
      // Shutting down
      setState(() => _isCameraActive = false);
      widget.controller?.updateState(active: false, transitioning: true);
      await Future.delayed(
        _animationDuration,
      ); // Wait for window blind to close

      if (!mounted) return; // Guard: Did user leave screen during animation?
      await _controller.stop();
      _idleTimer?.cancel();
    } else {
      // Starting up
      await _controller.start();

      if (!mounted) {
        return; // Guard: Did user leave screen while hardware booted?
      }
      setState(() => _isCameraActive = true);
      widget.controller?.updateState(active: true, transitioning: true);
      _resetIdleTimer();
    }

    if (mounted) {
      setState(() => _isTransitioning = false);
      await widget.controller?.updateState(
        active: _isCameraActive,
        transitioning: false,
      );
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    // Stream Cooldown Logic (prevents rapid-fire duplicate scans of the same item)
    if (rawValue == _lastScannedCode && _cooldownWatch.isRunning) {
      if (_cooldownWatch.elapsedMilliseconds < widget.sameItemCooldownMs) {
        return;
      }
    }

    _lastScannedCode = rawValue;
    _cooldownWatch
      ..reset()
      ..start();

    // Trigger Native Hardware Feedback
    if (widget.enableSoundAndVibration) {
      unawaited(_effects.playHaptic(HapticPattern.success));
      unawaited(_effects.play(NativeSound.scannerBeep));
    }

    _resetIdleTimer();

    // Pass data up to the Cart screen
    widget.onBarcodeScanned(rawValue);
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _cancelIdleTimer();
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the perfectly locked dimensions
            final double currentWidth = constraints.maxWidth;
            final double cameraHeight = currentWidth / 2.5;

            return Column(
              mainAxisSize: MainAxisSize.min, // Keep it tight
              children: [
                // 1. The Camera Window – expands from 0 → cameraHeight
                // MARK: - Camera Window
                ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    height: _isCameraActive ? cameraHeight : 0,
                    width: currentWidth,
                    // OverflowBox prevents the camera feed from squishing during the animation.
                    // It acts like a window blind smoothly revealing the full-size feed.
                    child: Stack(
                      children: [
                        // 1. The Camera Hardware (Pushed to background)
                        Positioned.fill(
                          child: OverflowBox(
                            minHeight: cameraHeight,
                            maxHeight: cameraHeight,
                            alignment: Alignment.topCenter,
                            child: MobileScanner(
                              key: const ValueKey('scanner'),
                              fit: BoxFit.cover,
                              controller: _controller,
                              useAppLifecycleState: false,
                              scanWindow: Rect.fromLTWH(
                                0,
                                0,
                                currentWidth,
                                cameraHeight,
                              ),
                            ),
                          ),
                        ),

                        // 2. The Minimalist Overlay
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: AnimatedOpacity(
                            opacity: (_isCameraActive && !_isTransitioning) ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: IgnorePointer(
                              ignoring: !_isCameraActive || _isTransitioning,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Close 'X' Button
                                  CircleButton(
                                    icon: Icons.close,
                                    size: 25,
                                    darkMode: widget.useDarkModeButtonTheme,
                                    onPressed: _toggleCamera,
                                  ),
                                  // Flashlight Toggle (Micro-rebuilds only when tapped)
                                  ValueListenableBuilder<MobileScannerState>(
                                    valueListenable: _controller,
                                    builder: (context, state, child) {
                                      return CircleButton(
                                        icon: state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                                        size: 25,
                                        darkMode: widget.useDarkModeButtonTheme,
                                        onPressed: () => _controller.toggleTorch(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (widget.showToggleButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: _isCameraActive ? _activeToggleStyle : _inactiveToggleStyle,
                      icon: _isTransitioning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : _isCameraActive
                          ? const Icon(Icons.stop)
                          : const Icon(Icons.play_arrow),
                      label: _isTransitioning
                          ? const SizedBox.shrink()
                          : _isCameraActive
                          ? const Text('Stop Camera')
                          : const Text('Start Camera'),
                      onPressed: _isTransitioning ? null : _toggleCamera,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
