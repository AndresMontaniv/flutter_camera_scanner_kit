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

// ─── Landscape chrome ───────────────────────────────────────────────────────
// In landscape every control moves to a screen *edge*: the toolbar buttons
// already hug the left and right edges, the quantity controls become a rail on
// the right, and the close button moves to the bottom-left corner. Because the
// scan window stays horizontally centred, keeping it clear of all of them is a
// single horizontal clamp — so no vertical space has to be reserved at all.

/// Maximum width of the close-camera button in landscape.
///
/// The button is the widest edge chrome — wider than the toolbar's 113 lp
/// flash+badge cluster and the 73 lp quantity rail — so it governs
/// [kLandscapeEdgeReserve]. The screen enforces this cap, which is what stops a
/// long custom `closeButtonLabel` from growing into the scan window.
const double kLandscapeCloseButtonMaxWidth = 138.0;

/// Horizontal space reserved at each screen edge in landscape.
///
/// The window stays centred, so the larger of the two sides' chrome governs
/// both. Clamping the window width to `screenWidth - 2 * this` guarantees it
/// clears the toolbar, the quantity rail and the close button simultaneously.
const double kLandscapeEdgeReserve = kLandscapeCloseButtonMaxWidth + kGap;

/// Bottom inset for the close button in landscape.
///
/// The portrait [kCloseMinBottomInset] of 100 lp exists for thumb reach on a
/// tall screen; on a ~400 lp landscape screen it would eat a quarter of the
/// height for no benefit.
const double kLandscapeCloseBottomInset = 13.0;

/// A resolved POS layout.
///
/// Two shapes, chosen by orientation:
///
/// * **Portrait** — everything shares one vertical axis, so the scan window and
///   the horizontal +/− row are solved together against a fixed height budget.
/// * **Landscape** — the controls live on the screen edges, so only the window
///   needs solving; the quantity rail and close button are positioned
///   declaratively by the screen.
@immutable
class PosLayout {
  /// The scan window rectangle, in logical pixels.
  final Rect scanWindow;

  /// The top edge of the horizontal +/− quantity row, in logical pixels.
  ///
  /// **Null in landscape**, where the controls become a vertical rail anchored
  /// to the right edge rather than a row at a solved offset.
  final double? qtyRowTop;

  /// Whether this layout describes the landscape arrangement.
  final bool isLandscape;

  /// Creates the portrait layout, where the quantity row is solved alongside
  /// the window.
  const PosLayout.portrait({
    required this.scanWindow,
    required double this.qtyRowTop,
  }) : isLandscape = false;

  /// Creates the landscape layout, where only the window needs solving.
  const PosLayout.landscape({required this.scanWindow})
    : qtyRowTop = null,
      isLandscape = true;
}

/// Solves the POS screen's layout for the current metrics.
///
/// Dispatches on orientation. The two arrangements are genuinely different —
/// portrait stacks everything on one axis and has to budget for it, landscape
/// pushes the controls to the edges and only has to keep the window clear of
/// them — so they are solved by separate functions rather than one branching
/// body.
PosLayout resolvePosLayout({
  required Size screenSize,
  required EdgeInsets viewPadding,
  required BarcodeWindowShape shape,
  required double qtyButtonsBottomPadding,
  Rect? scanWindowOverride,
}) {
  return screenSize.width > screenSize.height
      ? _resolveLandscapeLayout(
          screenSize: screenSize,
          viewPadding: viewPadding,
          shape: shape,
          scanWindowOverride: scanWindowOverride,
        )
      : _resolvePortraitLayout(
          screenSize: screenSize,
          viewPadding: viewPadding,
          shape: shape,
          qtyButtonsBottomPadding: qtyButtonsBottomPadding,
          scanWindowOverride: scanWindowOverride,
        );
}

/// Solves the **landscape** layout.
///
/// Every control sits on a screen edge here: the toolbar's buttons already hug
/// the left and right (`_SharedButtonsRow` is a `Row(spaceBetween)`), the
/// quantity controls become a right-hand rail, and the close button moves to
/// the bottom-left corner. The scan window stays horizontally centred, so
/// keeping it clear of all of them reduces to **one width clamp** — and that in
/// turn means no vertical chrome has to be reserved, which is what buys the
/// height back.
///
/// The height still gives way to the available band as a last resort, exactly
/// as in portrait, so `square` means "square where it fits".
PosLayout _resolveLandscapeLayout({
  required Size screenSize,
  required EdgeInsets viewPadding,
  required BarcodeWindowShape shape,
  Rect? scanWindowOverride,
}) {
  if (scanWindowOverride != null) {
    return PosLayout.landscape(scanWindow: scanWindowOverride);
  }

  // Keep the window clear of the edge controls on both sides.
  final double maxWidth = math.max(
    0.0,
    screenSize.width - 2 * kLandscapeEdgeReserve,
  );
  final double width = math.min(
    barcodeWindowSize(screenSize, shape).width,
    maxWidth,
  );

  // Nothing is subtracted for the toolbar, the rail or the close button.
  final double bandTop = viewPadding.top + kGap;
  final double bandBottom = screenSize.height - viewPadding.bottom - kGap;
  final double band = bandBottom - bandTop;

  final double desired = barcodeWindowHeightFor(width, shape);
  final double height = band <= 0.0 ? desired : math.min(desired, band);

  return PosLayout.landscape(
    scanWindow: Rect.fromCenter(
      center: Offset(screenSize.width / 2, bandTop + band / 2),
      width: width,
      height: height,
    ),
  );
}

/// Solves the **portrait** vertical budget.
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
PosLayout _resolvePortraitLayout({
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

  return PosLayout.portrait(scanWindow: window, qtyRowTop: qtyTop);
}
