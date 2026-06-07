import 'package:flutter/foundation.dart';

/// Controller that manages and synchronizes the active/transitioning state
/// of an embeddable [BarcodeScannerView].
///
/// This controller follows the **attach-and-observe** pattern: the
/// [BarcodeScannerView] calls [attach] during `initState` to bind its
/// internal toggle function to this controller. From that point forward,
/// external code can call [start], [stop], or [toggle] to programmatically
/// control the camera hardware, and observe [isCameraActive] and
/// [isTransitioning] to update UI accordingly.
///
/// ### UX Transition Floor
///
/// To prevent a jarring flash when the camera boots in under 100 ms, the
/// controller enforces a **minimum 500 ms transition duration**. If the
/// hardware initialises faster than this floor, the remaining time is padded
/// with `Future.delayed` so the user always sees a smooth loading indicator.
///
/// ### Lifecycle
///
/// This controller extends [ChangeNotifier]. Call `dispose()` when the
/// controller is no longer needed to release listeners.
///
/// ### Example
/// ```dart
/// class _ScanPageState extends State<ScanPage> {
///   final _scannerController = BarcodeScannerController();
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         BarcodeScannerView(
///           controller: _scannerController,
///           onBarcodeScanned: (code) => print('Scanned: $code'),
///         ),
///         ListenableBuilder(
///           listenable: _scannerController,
///           builder: (_, __) => Text(
///             _scannerController.isCameraActive ? 'Scanning…' : 'Idle',
///           ),
///         ),
///         ElevatedButton(
///           onPressed: _scannerController.toggle,
///           child: const Text('Toggle Camera'),
///         ),
///       ],
///     );
///   }
///
///   @override
///   void dispose() {
///     _scannerController.dispose();
///     super.dispose();
///   }
/// }
/// ```
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
  Future<void> updateState({
    required bool active,
    required bool transitioning,
  }) async {
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
    if (_toggleCallback == null) {
      debugPrint(
        '[camera_scanner_kit] WARN: Cannot toggle. BarcodeScannerController is not attached to a BarcodeScannerView.',
      );
      return;
    }

    if (_isTransitioning) {
      debugPrint(
        '[camera_scanner_kit] INFO: Camera is currently transitioning. Ignoring toggle request.',
      );
      return;
    }

    debugPrint('[camera_scanner_kit] INFO: Toggling camera state.');
    await _toggleCallback!();
  }

  /// Programmatically starts the camera feed.
  ///
  /// This method is idempotent. If the camera is already active, it will
  /// safely do nothing.
  Future<void> start() async {
    if (_isCameraActive) {
      debugPrint(
        '[camera_scanner_kit] INFO: Camera is already active. Ignoring start().',
      );
      return;
    }

    debugPrint('[camera_scanner_kit] INFO: Programmatically starting camera.');
    await toggle();
  }

  /// Programmatically stops the camera feed.
  ///
  /// This method is idempotent. If the camera is already stopped, it will
  /// safely do nothing.
  Future<void> stop() async {
    if (!_isCameraActive) {
      debugPrint(
        '[camera_scanner_kit] INFO: Camera is already stopped. Ignoring stop().',
      );
      return;
    }

    debugPrint('[camera_scanner_kit] INFO: Programmatically stopping camera.');
    await toggle();
  }
}
