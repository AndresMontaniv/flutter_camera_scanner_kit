import 'package:flutter/foundation.dart';

/// Controller that manages and synchronizes the active/transitioning state
/// of an embeddable [BarcodeScannerView].
///
/// Exposes methods to toggle the camera hardware and properties to inspect
/// whether the camera is booting or actively scanning.
class BarcodeScannerController extends ChangeNotifier {
  bool _isCameraActive = false;
  bool _isTransitioning = false;

  /// Whether the camera sensor is actively open and capturing frames.
  bool get isCameraActive => _isCameraActive;

  /// Whether the camera is currently starting up or shutting down.
  /// Useful for displaying progress indicators.
  bool get isTransitioning => _isTransitioning;

  Future<void> Function()? _toggleCallback;

  // Use a Stopwatch to measure exactly how long the hardware takes to boot
  final Stopwatch _stopwatch = Stopwatch();
  final Duration _minUxTransition = const Duration(milliseconds: 500);

  /// Binds the hardware toggle action of the scanner view to this controller.
  /// Intended for internal use by the [BarcodeScannerView].
  void attach(Future<void> Function() toggleCallback) {
    _toggleCallback = toggleCallback;
  }

  /// Updates the controller's internal state.
  /// Intended for internal use by the [BarcodeScannerView] to synchronize
  /// its hardware state to external listeners.
  Future<void> updateState({required bool active, required bool transitioning}) async {
    _isCameraActive = active;

    if (transitioning) {
      // 1. Hardware just started booting up. Lock the button and start the timer.
      _isTransitioning = true;
      _stopwatch
        ..reset()
        ..start();
      notifyListeners();
    } else {
      // 2. Hardware just finished! (Camera is now physically open and scanning)
      _stopwatch.stop();

      // 3. How fast was the hardware?
      final elapsed = _stopwatch.elapsed;

      if (elapsed < _minUxTransition) {
        // Hardware was faster than our 400ms UX floor. Pad the remaining time.
        await Future.delayed(_minUxTransition - elapsed);
      }

      // 4. Minimum time has passed. Unlock the external button.
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Toggles the camera scanner between active and inactive states.
  ///
  /// Safe to call repeatedly; double-taps are blocked internally while
  /// a transition is in progress.
  Future<void> toggle() async {
    // Prevent double-calls while already transitioning
    if (_toggleCallback != null && !_isTransitioning) {
      await _toggleCallback!();
    }
  }
}
