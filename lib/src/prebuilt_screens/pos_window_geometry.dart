/// Layout arithmetic for the POS scan window.
///
/// Split out of `pos_barcode_scanner_screen.dart` because that file **is**
/// exported wholesale by the package barrel — anything public there would leak
/// into the public API. This file is not exported, so the helpers below stay
/// package-internal while remaining directly unit-testable.
library;

import 'package:flutter/widgets.dart';

import '../widgets/scanner_view.dart';

/// The vertical offset used by the [BarcodeWindowShape.standard] POS window.
///
/// Preserved verbatim from 1.2.0 so the default POS screen is pixel-identical
/// across the upgrade.
const Offset kStandardPosOffset = Offset(0, -180);

/// Vertical space occupied by the +/− quantity row, plus a margin.
///
/// The row's height is driven by its `fontSize: 40` quantity label (~47 lp)
/// rather than by the 35 lp circular buttons beside it.
const double kQtyRowClearance = 56.0;

/// Resolves the vertical offset that centres a POS scan window of
/// [windowHeight] inside the band between the toolbar and the quantity row.
///
/// Pure by design so the fit can be unit-tested without a `BuildContext`.
Offset resolvePosWindowOffset({
  required Size screenSize,
  required EdgeInsets viewPadding,
  required double windowHeight,
  required double qtyButtonsBottomPadding,
}) {
  final double bandTop = viewPadding.top + kToolbarClearance;
  final double bandBottom =
      screenSize.height -
      viewPadding.bottom -
      qtyButtonsBottomPadding -
      kQtyRowClearance;

  // Degenerate layouts (tiny screens, huge qty padding) fall back to the
  // historic offset rather than producing a nonsensical rect; the vertical fit
  // inside `barcodeScanWindow` still keeps the window on screen.
  if (bandBottom <= bandTop) return kStandardPosOffset;

  final double targetCenterY = (bandTop + bandBottom) / 2;
  return Offset(0, targetCenterY - screenSize.height / 2);
}
