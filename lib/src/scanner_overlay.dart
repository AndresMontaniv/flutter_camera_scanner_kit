import 'package:flutter/material.dart';

/// Visual styling configurations for the camera overlay.
///
/// Allows customizing the background dimming, border color, corner radius,
/// and line thickness of the scanner's cut-out region.
class ScannerOverlayStyle {
  /// The opacity of the background dimming overlay (ranges from 0.0 to 1.0).
  /// Defaults to `0.5`.
  final double opacity;

  /// The color of the border bounding the cutout region.
  /// Defaults to [Colors.white].
  final Color borderColor;

  /// The base color of the background overlay (which will be dimmed via [opacity]).
  /// Defaults to [Colors.black].
  final Color opacityColor;

  /// The stroke width of the cutout border.
  /// Defaults to `2.5`.
  final double borderWidth;

  /// The corner radius of the cutout region.
  /// Defaults to `12.0`.
  final double borderRadius;

  /// Creates a style instance for customizing the scan window overlay.
  const ScannerOverlayStyle({
    double? opacity,
    Color? borderColor,
    Color? opacityColor,
    double? borderWidth,
    double? borderRadius,
  }) : opacity = opacity ?? 0.5,
       borderWidth = borderWidth ?? 2.5,
       borderRadius = borderRadius ?? 12.0,
       borderColor = borderColor ?? Colors.white,
       opacityColor = opacityColor ?? Colors.black;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannerOverlayStyle &&
          runtimeType == other.runtimeType &&
          opacity == other.opacity &&
          borderColor == other.borderColor &&
          opacityColor == other.opacityColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode => Object.hash(
        opacity,
        borderColor,
        opacityColor,
        borderWidth,
        borderRadius,
      );
}

class ScannerOverlay extends StatelessWidget {
  final BoxConstraints constraints;
  final Rect scanWindow;
  final ScannerOverlayStyle? style;

  const ScannerOverlay({
    super.key,
    required this.constraints,
    required this.scanWindow,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: constraints,
      child: CustomPaint(
        painter: _OverlayPainter(
          scanWindow: scanWindow,
          style: style,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The highly optimized painter
class _OverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final ScannerOverlayStyle style;

  const _OverlayPainter({
    required this.scanWindow,
    ScannerOverlayStyle? style,
  }) : style = style ?? const ScannerOverlayStyle();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the semi-transparent background
    final backgroundPaint = Paint()
      ..color = style.opacityColor.withValues(alpha: style.opacity)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // We use your exact scanWindow Rect here
    final scanRRect = RRect.fromRectAndRadius(
      scanWindow,
      Radius.circular(style.borderRadius),
    );

    final cutoutPath = Path()
      ..addRRect(scanRRect)
      ..close();

    // Path.combine is highly performant. It punches the hole out
    // mathematically before drawing, avoiding the need for expensive BlendModes.
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, backgroundPaint);

    // 2. Draw the border
    final borderPaint = Paint()
      ..color = style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth;

    canvas.drawRRect(scanRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow || oldDelegate.style != style;
  }
}
