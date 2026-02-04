import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/qr_result_screen.dart';
import 'models/scan_entry.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import 'qr_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _isScanning = false;
  bool _handlingResult = false;

  // Optional: prevent same QR from popping again immediately
  String? _lastCode;
  DateTime? _lastScanAt;

  Future<void> _startScanning() async {
    if (!mounted) return;

    // ✅ Web / Desktop: DO NOT use permission_handler (web permissions are browser-managed)
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      setState(() {
        _isScanning = true;
        _handlingResult = false;
      });

      try {
        await _controller.start();
      } catch (_) {}

      return;
    }

    // ✅ Android/iOS/macOS: request permission
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _isScanning = true;
        _handlingResult = false;
      });

      try {
        await _controller.start();
      } catch (_) {}
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera permission is required to scan.')),
    );
  }

  Future<void> _stopScanning() async {
    try {
      await _controller.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isScanning = false);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
  if (_handlingResult) return;
  if (capture.barcodes.isEmpty) return;

  final code = capture.barcodes.first.rawValue;
  if (code == null || code.isEmpty) return;

  // Debounce same code
  final now = DateTime.now();
  if (_lastCode == code &&
      _lastScanAt != null &&
      now.difference(_lastScanAt!).inMilliseconds < 1200) {
    return;
  }
  _lastCode = code;
  _lastScanAt = now;

  _handlingResult = true;
  if (!mounted) return;

  // ✅ Parse your 4-line prominent QR (if matches)
  final parsed = parseProminentQr(code);

  // ✅ Save to Hive database (works on Web + Android)
  try {
    final box = Hive.box<ScanEntry>('scans');
    await box.add(
      ScanEntry(
        timestampIso: DateTime.now().toIso8601String(),
        raw: code,
        name: parsed?.name,
        id: parsed?.id,
        position: parsed?.position,
        company: parsed?.company,
      ),
    );
  } catch (_) {
    // Optional: show snackbar if you want
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Failed to save scan.')),
    // );
  }

  // Optional: pause camera while viewing result
  try {
    await _controller.stop();
  } catch (_) {}

  // Go to result screen
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QrResultScreen(code: code),
    ),
  );

  // When user goes back, resume scanning (only if still in scan mode)
  if (!mounted) return;
  try {
    if (_isScanning) await _controller.start();
  } catch (_) {}

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
            if (_isScanning) ...[
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
              ),

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

            if (!_isScanning) ...[
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
