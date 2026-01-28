import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _isScanning = false;

  // Locks handling so we don't spam dialogs.
  bool _handlingResult = false;

  Future<void> _startScanning() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _isScanning = true;
        _handlingResult = false;
      });

      // Start camera preview
      await _controller.start();
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    // denied / restricted -> optional: show a snackbar/dialog
  }

  Future<void> _stopScanning() async {
    await _controller.stop();
    if (!mounted) return;
    setState(() => _isScanning = false);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingResult) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _handlingResult = true;

    if (!mounted) return;

    // ✅ Keep camera ON: do NOT stop controller and do NOT set _isScanning=false.
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('QR Result'),
        content: Text(code),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Small debounce (optional). Helps avoid immediate re-trigger on the same QR.
    await Future.delayed(const Duration(milliseconds: 250));

    _handlingResult = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B7FFF), Color(0xFF980FFA)],
          ),
        ),
        child: Stack(
          children: [
            // ===== Scanner view (shows only when scanning) =====
            if (_isScanning) ...[
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
              ),

              // Top glass bar over camera
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: topPad + 65,
                  padding: EdgeInsets.only(left: 16, right: 8, top: topPad),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    border: const Border(
                      bottom: BorderSide(color: Color(0x33FFFEFE), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'QR Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _stopScanning,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Simple scan frame overlay
              Center(
                child: Container(
                  width: size.width * 0.70,
                  height: size.width * 0.70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Optional: show "Paused" overlay while dialog is open (visual feedback)
              if (_handlingResult)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.15),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // ===== Your original UI (shows when not scanning) =====
            if (!_isScanning) ...[
              // Top App Bar (safe for notch)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: topPad + 65,
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 24, top: topPad),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    border: const Border(
                      bottom: BorderSide(color: Color(0x33FFFEFE), width: 1),
                    ),
                  ),
                  child: const Text(
                    'QR Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              Center(
                child: Container(
                  width: size.width > 500 ? 448 : size.width * 0.9,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x33FFFEFE),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Scan QR Code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap the button below to start scanning QR codes with your camera',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xCCFFFEFE),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startScanning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Start Scanning',
                            style: TextStyle(
                              color: Color(0xFF9810FA),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
