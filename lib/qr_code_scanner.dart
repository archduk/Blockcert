import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    autoStart: true,
  );

  bool _isScanning = true;
  bool _isTorchOn = false;
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: _isTorchOn
                ? const Icon(Icons.flash_on, color: Colors.yellow)
                : const Icon(Icons.flash_off, color: Colors.grey),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
                cameraController.toggleTorch();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _isScanning = false;
                scannedData = barcodes.first.rawValue;
                Navigator.pop(context, scannedData);
              }
            },
          ),
          // Enhanced QR Frame Overlay
          _buildScannerOverlay(context),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Align QR code within the frame to scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final frameSize = (width < height ? width : height) * 0.7;
        final left = (width - frameSize) / 2;
        final top = (height - frameSize) / 2;

        return Stack(
          children: [
            // Semi-transparent overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                ),
              ),
            ),
            // Transparent frame area
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Frame border with animated corners
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: CustomPaint(
                  painter: _CornerPainter(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cornerLength = size.width * 0.15;

    // Top-left corner
    canvas.drawLine(Offset.zero, Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, cornerLength), paint);

    // Top-right corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}