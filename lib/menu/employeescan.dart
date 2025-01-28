import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parking1/cash/receip.dart';


class EmployeeScan extends StatefulWidget {
  const EmployeeScan({super.key});

  @override
  State<EmployeeScan> createState() => _EmployeeScanState();
}

class _EmployeeScanState extends State<EmployeeScan> {
  bool _isProcessing = false;

  void _handleScan(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Print the scanned QR code to the console
    print("Scanned QR Code: $code");

    // Navigate to a new page with the scanned QR code
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultPage(qrCode: code),
      ),
    );

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Scan"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture barcodeCapture) {
              for (final Barcode barcode in barcodeCapture.barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  final String code = barcode.rawValue!;
                  _handleScan(code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Align QR code here",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: const Text(
                "Point the camera at a QR code to scan.",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanResultPage extends StatelessWidget {
  final String qrCode;

  const ScanResultPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Result"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Scanned QR Code:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                qrCode,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                MaterialPageRoute route =
                    MaterialPageRoute(builder: (c) => BillPage());
                Navigator.of(context).push(route);
                },
                child: const Text("ຢືນຢັນ"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
