import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'action_button.dart';
import 'scanner_overlay.dart';
import 'scanner_screen.dart';

const _defaultBorderColor = Colors.blue;
const _defaultPulseColor = Colors.cyanAccent;
const _defaultCloseButtonLabel = 'Close Camera';

/// A full-screen barcode scanner optimized for Point of Sale (POS) environments.
///
/// Provides a dedicated overlay containing quantity control buttons (+ / -),
/// real-time haptic/audio success feedback, and a reactive badge that shows the
/// list of scanned items in a modal bottom sheet.
class PosBarcodeScannerScreen extends StatefulWidget {
  /// Callback triggered when a barcode is scanned, providing the raw code
  /// and the quantity selected by the user.
  final void Function(String barcode, int qty) onScan;

  /// The active set of barcode formats to restrict scan detection to.
  final List<BarcodeFormat> allowedFormats;

  /// The minimum delay in milliseconds before a new barcode can be scanned.
  final int detectionTimeoutMs;

  /// The minimum time in milliseconds before the same barcode can be scanned again.
  final int sameItemCooldownMs;

  /// Whether to play haptic vibrations and sound effects on successful scans.
  final bool enableSoundAndVibration;

  /// Optional offset to shift the vertical alignment of the scan window cutout.
  final Offset? offsetFromCenter;

  /// Custom visual overlay styling (e.g. border color, line thickness).
  final ScannerOverlayStyle? overlayStyle;

  /// Whether to render the control buttons with dark backgrounds.
  final bool useDarkModeButtonTheme;

  /// The bottom padding for placing the quantity adjustment buttons.
  final double qtyButtonsBottomPadding;

  /// Optional custom label text to display on the close button.
  final String? closeButtonLabel;

  /// The background pulse color flashed upon a successful scan.
  final Color? successPulseColor;

  /// Creates a [PosBarcodeScannerScreen] instance.
  const PosBarcodeScannerScreen({
    super.key,
    required this.onScan,
    this.allowedFormats = const <BarcodeFormat>[],
    this.detectionTimeoutMs = 250,
    this.sameItemCooldownMs = 1500,
    this.enableSoundAndVibration = true,
    this.offsetFromCenter,
    this.overlayStyle,
    this.closeButtonLabel,
    this.successPulseColor,
    this.useDarkModeButtonTheme = true,
    this.qtyButtonsBottomPadding = 230,
  }) : assert(
         qtyButtonsBottomPadding > 0,
         'qtyButtonsBottomPadding must be greater than 0',
       );

  @override
  State<PosBarcodeScannerScreen> createState() =>
      _PosBarcodeScannerScreenState();
}

class _PosBarcodeScannerScreenState extends State<PosBarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int> qtyNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> totalItemsNotifier = ValueNotifier<int>(0);
  Map<String, int> scannedBarcodes = {};

  late final AnimationController _feedbackController;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    // The Controller (Fast 150ms trigger)
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 250),
    );

    // The Ghost Pulse (Fades from 0.0 to 0.25 opacity)
    _pulseOpacity = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );

    // The Button Bounce (Scales from 100% to 125% size)
    _buttonScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOutBack),
    );
  }

  void _onShowScanListPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ValueListenableBuilder<int>(
              valueListenable: totalItemsNotifier,
              builder: (context, totalLength, _) {
                final list = scannedBarcodes.entries.toList();
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Scanned Barcodes ($totalLength)',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Empty State (Just in case)
                    if (list.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No items scanned yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      )
                    // Scrollable List
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: scannedBarcodes.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final qty = item.value;
                            final barcode = item.key;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                foregroundColor: Colors.blue.shade900,
                                child: Text('$qty x'),
                              ),
                              title: Text(
                                barcode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScanListButton() {
    final actionButtonTheme = widget.useDarkModeButtonTheme
        ? ActionButtonTheme.dark
        : ActionButtonTheme.light;
    final borderColor = widget.overlayStyle?.borderColor ?? _defaultBorderColor;
    return ValueListenableBuilder<int>(
      valueListenable: totalItemsNotifier,
      builder: (ctx, total, _) {
        return ScaleTransition(
          scale: _buttonScale,
          child: IconButton(
            onPressed: _onShowScanListPressed,
            style: actionButtonTheme.buttonStyle.copyWith(
              fixedSize: const WidgetStatePropertyAll(Size(55, 55)),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              shape: WidgetStatePropertyAll(
                CircleBorder(side: BorderSide(color: borderColor, width: 2.0)),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            icon: Text(total.toString()),
          ),
        );
      },
    );
  }

  Widget _buildCloseCameraTextButton() {
    final actionButtonTheme = widget.useDarkModeButtonTheme
        ? ActionButtonTheme.dark
        : ActionButtonTheme.light;
    final borderColor = actionButtonTheme.borderColor;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        bottom: true,
        top: false,
        right: false,
        left: false,
        minimum: const EdgeInsets.only(bottom: 100),
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: actionButtonTheme.buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
            ),
          ),
          child: Text(widget.closeButtonLabel ?? _defaultCloseButtonLabel),
        ),
      ),
    );
  }

  void _onCameraScan(String barcode) {
    final qty = qtyNotifier.value;
    widget.onScan(barcode, qty);
    scannedBarcodes[barcode] = (scannedBarcodes[barcode] ?? 0) + qty;
    totalItemsNotifier.value += qty;

    // Trigger the Ghost Pulse and Button Bounce
    _feedbackController.forward(from: 0.0).then((_) {
      if (mounted) _feedbackController.reverse();
    });

    // After scan reset qty to 1
    qtyNotifier.value = 1;
  }

  @override
  void dispose() {
    qtyNotifier.dispose();
    totalItemsNotifier.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScannerScreen.multiscan(
      toolBar: StandardToolBar(
        showSwitchCameraButton: false,
        trailing: [_buildScanListButton()],
      ),
      allowDuplicates: true,
      detectionTimeoutMs: widget.detectionTimeoutMs,
      sameItemCooldownMs: widget.sameItemCooldownMs,
      enableSoundAndVibration: widget.enableSoundAndVibration,
      useDarkModeButtonTheme: widget.useDarkModeButtonTheme,
      scannerViewConfig: ScannerViewConfig.barcode(
        overlayStyle:
            widget.overlayStyle ??
            const ScannerOverlayStyle(borderColor: _defaultBorderColor),
        offsetFromCenter: widget.offsetFromCenter,
        allowedFormats: widget.allowedFormats,
      ),
      onCameraScan: _onCameraScan,
      stackChildren: [
        // Ghost Pulse overlay
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _pulseOpacity,
              child: Container(
                color: widget.successPulseColor ?? _defaultPulseColor,
              ),
            ),
          ),
        ),
        Positioned(
          bottom:
              MediaQuery.of(context).padding.bottom +
              widget.qtyButtonsBottomPadding,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<int>(
            valueListenable: qtyNotifier,
            builder: (context, qty, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleButton(
                    icon: Icons.remove,
                    size: 35,
                    darkMode: widget.useDarkModeButtonTheme,
                    onPressed: () {
                      if (qty > 1) qtyNotifier.value--;
                    },
                  ),
                  Text(
                    qty.toString(),
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleButton(
                    icon: Icons.add,
                    size: 35,
                    darkMode: widget.useDarkModeButtonTheme,
                    onPressed: () {
                      qtyNotifier.value++;
                    },
                  ),
                ],
              );
            },
          ),
        ),
        _buildCloseCameraTextButton(),
      ],
    );
  }
}
