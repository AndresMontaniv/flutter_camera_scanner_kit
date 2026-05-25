import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'action_button.dart';
import 'scanner_overlay.dart';
import 'scanner_screen.dart';

const _defaultBorderColor = Colors.blue;
const _defaultCloseButtonLabel = 'Close Camera';

class PosBarcodeScannerScreen extends StatefulWidget {
  final void Function(String barcode, int qty) onScan;
  final List<BarcodeFormat> allowedFormats;
  final int detectionTimeoutMs;
  final int sameItemCooldownMs;
  final bool enableSoundAndVibration;
  final Offset? offsetFromCenter;
  final ScannerOverlayStyle? overlayStyle;
  final bool useDarkModeButtonTheme;
  final double qtyButtonsBottomPadding;
  final String? closeButtonLabel;

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
    this.useDarkModeButtonTheme = true,
    this.qtyButtonsBottomPadding = 230,
  }) : assert(qtyButtonsBottomPadding > 0, 'qtyButtonsBottomPadding must be greater than 0');

  @override
  State<PosBarcodeScannerScreen> createState() => _PosBarcodeScannerScreenState();
}

class _PosBarcodeScannerScreenState extends State<PosBarcodeScannerScreen> {
  final ValueNotifier<int> qtyNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> totalItemsNotifier = ValueNotifier<int>(0);
  Map<String, int> scannedBarcodes = {};

  void _onShowScanListPressed() {
    final length = totalItemsNotifier.value;
    final list = scannedBarcodes.entries.toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scanned Barcodes ($length)',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
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
                      child: Text('No items scanned yet.', style: TextStyle(fontSize: 16, color: Colors.black54)),
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
                          leading: CircleAvatar(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900, child: Text('$qty x')),
                          title: Text(barcode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
  }

  Widget _buildScanListButton() {
    final actionButtonTheme = widget.useDarkModeButtonTheme ? ActionButtonTheme.dark : ActionButtonTheme.light;
    final borderColor = widget.overlayStyle?.borderColor ?? _defaultBorderColor;
    return ValueListenableBuilder<int>(
      valueListenable: totalItemsNotifier,
      builder: (ctx, total, _) {
        return IconButton(
          onPressed: _onShowScanListPressed,
          style: actionButtonTheme.buttonStyle.copyWith(
            fixedSize: const WidgetStatePropertyAll(Size(55, 55)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(CircleBorder(side: BorderSide(color: borderColor, width: 2.0))),
          ),
          icon: Text(
            total.toString(),
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              height: 1.0,
              color: widget.useDarkModeButtonTheme ? Colors.white : Colors.black87,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloseCameraTextButton() {
    final actionButtonTheme = widget.useDarkModeButtonTheme ? ActionButtonTheme.dark : ActionButtonTheme.light;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        bottom: true,
        top: false,
        right: false,
        left: false,
        minimum: const EdgeInsets.only(bottom: 100),
        child: TextButton(
          onPressed: () {},
          style: actionButtonTheme.buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          child: Text(
            widget.closeButtonLabel ?? _defaultCloseButtonLabel,
            style: TextStyle(
              color: widget.useDarkModeButtonTheme ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _onCameraScan(String barcode) {
    final qty = qtyNotifier.value;
    widget.onScan(barcode, qty);
    scannedBarcodes[barcode] = (scannedBarcodes[barcode] ?? 0) + qty;
    totalItemsNotifier.value += qty;
    // After scan reset qty to 1
    qtyNotifier.value = 1;
  }

  @override
  void dispose() {
    qtyNotifier.dispose();
    totalItemsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScannerScreen.multiscan(
      toolBar: StandardToolBar(showSwitchCameraButton: false, trailing: [_buildScanListButton()]),
      allowDuplicates: true,
      detectionTimeoutMs: widget.detectionTimeoutMs,
      sameItemCooldownMs: widget.sameItemCooldownMs,
      enableSoundAndVibration: widget.enableSoundAndVibration,
      useDarkModeButtonTheme: widget.useDarkModeButtonTheme,
      scannerViewConfig: ScannerViewConfig.barcode(
        overlayStyle: widget.overlayStyle ?? const ScannerOverlayStyle(borderColor: _defaultBorderColor),
        offsetFromCenter: widget.offsetFromCenter,
        allowedFormats: widget.allowedFormats,
      ),
      onCameraScan: _onCameraScan,
      stackChildren: [
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + widget.qtyButtonsBottomPadding,
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
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
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
