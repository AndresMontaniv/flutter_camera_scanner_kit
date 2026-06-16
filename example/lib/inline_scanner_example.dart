import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoTextField;
import 'package:camera_scanner_kit/camera_scanner_kit.dart';

class InlineScannerExample extends StatefulWidget {
  final bool useDarkMode;
  const InlineScannerExample({super.key, required this.useDarkMode});

  @override
  State<InlineScannerExample> createState() => _InlineScannerExampleState();
}

class _InlineScannerExampleState extends State<InlineScannerExample> {
  final BarcodeScannerController _scannerController =
      BarcodeScannerController();
  final List<String> _scannedItems = [];

  void _onScanned(String barcode) {
    setState(() {
      _scannedItems.insert(0, barcode); // Add to top of list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inline Scanner Demo')),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: [
            // 1. The Embedded Scanner View
            BarcodeScannerView(
              borderRadius: BorderRadius.zero,
              controller: _scannerController,
              showToggleButton: true,
              useDarkModeButtonTheme: widget.useDarkMode,
              onBarcodeScanned: _onScanned,
            ),
            const SizedBox(height: 20),

            // 2. External Controls (Simulating a Search Bar)
            Row(
              children: [
                const Expanded(
                  child: CupertinoTextField(
                    readOnly: true,
                    placeholder: 'Tap barcode icon to scan...',
                    prefix: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.search, color: Colors.black45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // The Reactive Toggle Button
                ListenableBuilder(
                  listenable: _scannerController,
                  builder: (context, _) {
                    final isActive = _scannerController.isCameraActive;
                    final isTransitioning = _scannerController.isTransitioning;

                    return IconButton(
                      onPressed: isTransitioning
                          ? null
                          : _scannerController.toggle,
                      icon: isTransitioning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(isActive ? Icons.close : Icons.barcode_reader),
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.black45),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          isActive ? Colors.red.shade100 : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 40),

            // 3. Results List
            Text(
              'Scanned Codes: ${_scannedItems.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _scannedItems.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(_scannedItems[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
