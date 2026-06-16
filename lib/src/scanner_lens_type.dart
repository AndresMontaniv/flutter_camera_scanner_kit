import 'package:mobile_scanner/mobile_scanner.dart';

/// Defines the physical camera lens to be used for barcode scanning.
///
/// Note on Hardware Fragmentation:
/// * **iOS (Pro Models):** When using [any], iOS may rapidly switch between lenses
///   to find macro focus, causing a visual "jump". For inline scanners on Pro iPhones,
///   passing [wide] locks the ultra-wide lens and provides a smoother, jump-free UX.
/// * **Android & Lower-End iOS:** Many mid-range Androids and base-model iPhones
///   (like iPhone SE) do not expose ultra-wide or zoom lenses to third-party apps.
///   Passing [wide] or [zoom] on these devices will cause the camera to return
///   as unavailable.
///
/// **Recommendation:** Default to [any] for maximum device compatibility.
/// Only hardcode specific lenses if you are handling fallback logic in your app.
enum ScannerLensType {
  /// Allows the OS to automatically choose and switch lenses. Safest default.
  any,

  /// The ultra-wide angle lens. Best for close-up macro scanning on supported iOS devices.
  wide,

  /// The standard wide angle lens.
  normal,

  /// The telephoto/zoom lens.
  zoom
  ;

  /// Internal mapper to the underlying mobile_scanner package enum.
  CameraLensType get mobileScannerLens {
    return switch (this) {
      ScannerLensType.any => CameraLensType.any,
      ScannerLensType.wide => CameraLensType.wide,
      ScannerLensType.normal => CameraLensType.normal,
      ScannerLensType.zoom => CameraLensType.zoom,
    };
  }
}
