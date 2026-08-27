import 'package:flutter/material.dart';
import 'package:camera_scanner_kit/camera_scanner_kit.dart';
import 'inline_scanner_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner Matrix Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestMatrixScreen(),
    );
  }
}

class TestMatrixScreen extends StatefulWidget {
  const TestMatrixScreen({super.key});

  @override
  State<TestMatrixScreen> createState() => _TestMatrixScreenState();
}

class _TestMatrixScreenState extends State<TestMatrixScreen> {
  bool _useDarkModeButtonTheme = true;

  void _showResult(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Scanner Sandbox')),
      body: ListView(
        children: [
          CheckboxListTile(
            value: _useDarkModeButtonTheme,
            title: const Text('Use darkMode theme on Action Buttons'),
            onChanged: (value) {
              setState(() {
                _useDarkModeButtonTheme = value ?? true;
              });
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '0. TEST THIS FEATURES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          ListTile(
            title: const Text('Test Inline Scanner (Controller Demo)'),
            subtitle: const Text('Embeddable view with external toggle'),
            trailing: const Icon(Icons.crop_free),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InlineScannerExample(
                    useDarkMode: _useDarkModeButtonTheme,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('POS with qty buttons'),
            trailing: const Icon(Icons.shopping_bag_outlined),
            onTap: () {
              showPosBarcodeScanner(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                closeButtonLabel: 'Cerrar Cámara',
                onScan: (barcode, qty) {
                  debugPrint(
                    '[ScannerExample] This barcode x times: $barcode x $qty',
                  );
                  if (!context.mounted) return;
                  _showResult(context, 'This barcode x times: $barcode x $qty');
                },
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '1. SINGLE SCAN MODE',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            title: const Text('Single + QR Code'),
            trailing: const Icon(Icons.qr_code),
            onTap: () async {
              final result = await scanQrCode(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                lensType: ScannerLensType.normal,
                overlayStyle: const ScannerOverlayStyle(
                  borderColor: Colors.blue,
                ),
              );
              debugPrint('[ScannerExample] Single QR Result: $result');
              if (!context.mounted) return;
              _showResult(context, 'Single QR: $result');
            },
          ),
          ListTile(
            title: const Text('Single + Barcode'),
            trailing: const Icon(Icons.view_column),
            onTap: () async {
              final result = await scanBarcode(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                // Test .wide on iOS
                // lensType: ScannerLensType.wide,
                overlayStyle: const ScannerOverlayStyle(
                  borderColor: Colors.pink,
                ),
              );
              debugPrint('[ScannerExample] Single Barcode Result: $result');
              if (!context.mounted) return;
              _showResult(context, 'Single Barcode: $result');
            },
          ),
          ListTile(
            title: const Text('Single + Custom'),
            trailing: const Icon(Icons.fullscreen),
            onTap: () async {
              final screenSize = MediaQuery.sizeOf(context);
              final result = await scanCustom(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                scannerViewConfig: ScannerViewConfig(
                  scanWindow: Rect.fromCenter(
                    center: screenSize.center(Offset.zero),
                    width: 200,
                    height: 200,
                  ),
                ),
              );
              debugPrint('[ScannerExample] Single Custom Result: $result');
              if (!context.mounted) return;
              _showResult(context, 'Single Custom: $result');
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '2. BATCH POP MODE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          ListTile(
            title: const Text('Batch + QR Code (REJECT Duplicates)'),
            subtitle: const Text('Test cart list button'),
            trailing: const Icon(Icons.qr_code),
            onTap: () async {
              final result = await scanQrCodeBatch(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                allowDuplicates: false,
              );
              debugPrint('[ScannerExample] Batch QR Result: $result');
            },
          ),
          ListTile(
            title: const Text('Batch + Barcode (Allow Duplicates)'),
            subtitle: const Text('Scan same item twice to test'),
            trailing: const Icon(Icons.view_column),
            onTap: () async {
              final result = await scanBarcodeBatch(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                allowDuplicates: true,
              );
              debugPrint('[ScannerExample] Batch Barcode Result: $result');
            },
          ),
          ListTile(
            title: const Text('Batch + Custom'),
            trailing: const Icon(Icons.fullscreen),
            onTap: () async {
              final screenSize = MediaQuery.sizeOf(context);
              final result = await scanCustomBatch(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                toolBar: const BatchToolBar(),
                scannerViewConfig: ScannerViewConfig(
                  scanWindow: Rect.fromCenter(
                    center: screenSize.center(Offset.zero),
                    width: 80,
                    height: 300,
                  ),
                  overlayStyle: const ScannerOverlayStyle(
                    borderColor: Colors.yellow,
                    borderRadius: 40.0,
                  ),
                ),
              );
              debugPrint('[ScannerExample] Batch Custom Result: $result');
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '3. CALLBACK STREAM MODE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          ListTile(
            title: const Text('Stream + QR Code'),
            subtitle: const Text('Watch debug console for real-time prints'),
            trailing: const Icon(Icons.qr_code),
            onTap: () async {
              await scanQrCodeStream(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                onCameraScan: (qrCode) {
                  debugPrint('[ScannerExample] STREAM DETECTED: $qrCode');
                  _showResult(context, 'Stream QR: $qrCode');
                },
              );
            },
          ),
          ListTile(
            title: const Text('Stream + Barcode (REJECT Duplicates)'),
            subtitle: const Text('Scan same item twice to test Reject buzz'),
            trailing: const Icon(Icons.view_column),
            onTap: () async {
              await scanBarcodeStream(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                allowDuplicates: false,
                onCameraScan: (barcode) {
                  debugPrint('[ScannerExample] STREAM DETECTED: $barcode');
                  _showResult(context, 'Stream Barcode: $barcode');
                },
              );
            },
          ),
          ListTile(
            title: const Text('Stream + Custom'),
            trailing: const Icon(Icons.fullscreen),
            onTap: () async {
              await scanCustomStream(
                context,
                useDarkModeButtonTheme: _useDarkModeButtonTheme,
                onCameraScan: (barcode) {
                  debugPrint('[ScannerExample] STREAM DETECTED: $barcode');
                  _showResult(context, 'Stream Custom: $barcode');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
