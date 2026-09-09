/// Layout arithmetic for the POS scanner screen.
///
/// Split out of `pos_barcode_scanner_screen.dart` because that file **is**
/// exported wholesale by the package barrel — anything public there would leak
/// into the public API. This file is not exported, so the helpers below stay
/// package-internal while remaining directly unit-testable.
///
/// Everything here is pure: no `BuildContext`, no `MediaQuery`. The screen
/// reads the platform values once and hands them in.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../widgets/scanner_view.dart';

// ─── Measured chrome ────────────────────────────────────────────────────────
// Heights read off the widget tree, not estimated. They assume the default
// text scale; the POS screen's chrome is icon-driven, so the only text that
// could grow is the quantity label, which the 35 lp buttons already outsize.

/// Padding around the toolbar row — `StandardToolBar`'s `EdgeInsets.all(16)`.
const double kToolbarPadding = 16.0;

/// Height of the POS toolbar row.
///
/// Driven by the scan-list badge (`SizedBox(width: 55, height: 55)` plus its
/// border), **not** by the 44 lp flash/close buttons beside it. Getting this
/// wrong is what let the scan window slide under the toolbar.
const double kPosToolbarRowHeight = 57.0;

/// Height of the +/− quantity row.
///
/// `CircleButton(size: 35)` renders 35 lp of icon inside `EdgeInsets.all(8)`
/// plus a hairline border. That beats the ~47 lp quantity label beside it.
const double kQtyRowHeight = 53.0;

/// Height of the close-camera button — label plus `vertical: 12` padding.
const double kCloseButtonHeight = 42.0;

/// Minimum gap the close button keeps from the bottom edge, for thumb reach.
///
/// Mirrors `SafeArea(minimum: EdgeInsets.only(bottom: 100))` on the button
/// itself; the larger of this and the device's bottom inset wins.
const double kCloseMinBottomInset = 100.0;

/// The breathing room kept between any two stacked elements.
const double kGap = 16.0;

/// The vertical nudge the scan window prefers, carried over from 1.2.0.
///
/// Negative because the rear camera sits at the top of the phone, so a window
/// above centre is more comfortable to aim. The solver treats this as a
/// *preference* and relaxes it only when a constraint would be violated.
const Offset kPreferredPosOffset = Offset(0, -180);

/// A resolved POS layout: where the scan window goes and where the quantity
/// row goes, solved together so the two can never disagree.
@immutable
class PosLayout {
  /// The scan window rectangle, in logical pixels.
  final Rect scanWindow;

  /// The top edge of the +/− quantity row, in logical pixels.
  final double qtyRowTop;

  /// Creates a resolved layout.
  const PosLayout({required this.scanWindow, required this.qtyRowTop});
}

/// Solves the POS screen's vertical budget.
///
/// Portrait height is fixed, so the chrome claims its space first and the scan
/// window takes what is left. The solve is a **constraint relaxation**: it
/// starts from exactly the geometry 1.2.0 shipped and moves things only when
/// they would collide, in a fixed order of preference:
///
/// 1. Keep the window at [kPreferredPosOffset].
/// 2. If it would reach the toolbar, push the window **down**.
/// 3. If it would reach the quantity row, slide the **row down**.
/// 4. If the row runs out of travel, **shrink the window** — last resort.
///
/// Because every step is a clamp, a layout that already fits is returned
/// untouched. That is what keeps existing screens pixel-identical.
///
/// When [scanWindowOverride] is supplied — a caller passing their own [Rect]
/// through `showPosScanner` — steps 1, 2 and 4 are skipped entirely: the rect
/// is used verbatim. Step 3 still runs, so the quantity row is placed as well
/// as it can be rather than landing on top of the window.
PosLayout resolvePosLayout({
  required Size screenSize,
  required EdgeInsets viewPadding,
  required BarcodeWindowShape shape,
  required double qtyButtonsBottomPadding,
  Rect? scanWindowOverride,
}) {
  // ── Chrome claims its space first ──
  final double toolbarBottom =
      viewPadding.top + kToolbarPadding + kPosToolbarRowHeight;
  final double closeTop =
      screenSize.height -
      math.max(viewPadding.bottom, kCloseMinBottomInset) -
      kCloseButtonHeight;

  final double bandTop = toolbarBottom + kGap;
  // How far down the quantity row is allowed to travel before it would crowd
  // the close button.
  final double qtyTopMax = closeTop - kGap - kQtyRowHeight;
  final double winBottomMax = qtyTopMax - kGap;

  // ── The scan window ──
  final Rect window;
  if (scanWindowOverride != null) {
    window = scanWindowOverride;
  } else {
    final Size size = barcodeWindowSize(screenSize, shape);

    // Step 4. A window taller than the band gives up height rather than
    // overlapping; `square` then means "square where it fits, as tall as
    // possible otherwise".
    final double band = winBottomMax - bandTop;
    final double height = band <= 0.0
        ? size.height
        : math.min(size.height, band);

    // Steps 1-2. Hold the preferred centre; relax only on violation.
    final double minCenter = bandTop + height / 2;
    final double maxCenter = winBottomMax - height / 2;
    final double preferred = screenSize.height / 2 + kPreferredPosOffset.dy;
    final double centerY = maxCenter < minCenter
        ? minCenter
        : preferred.clamp(minCenter, maxCenter);

    window = Rect.fromCenter(
      center: Offset(
        screenSize.width / 2 + kPreferredPosOffset.dx,
        centerY,
      ),
      width: size.width,
      height: height,
    );
  }

  // ── Step 3: the quantity row yields ground only if the window needs it ──
  final double qtyTopPreferred =
      screenSize.height -
      viewPadding.bottom -
      qtyButtonsBottomPadding -
      kQtyRowHeight;
  final double qtyTopWanted = math.max(
    qtyTopPreferred,
    window.bottom + kGap,
  );
  final double qtyTop = qtyTopMax < qtyTopPreferred
      ? qtyTopPreferred
      : qtyTopWanted.clamp(qtyTopPreferred, qtyTopMax);

  return PosLayout(scanWindow: window, qtyRowTop: qtyTop);
}
