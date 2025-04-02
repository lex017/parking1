import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parking1/menu/emp_check.dart';

class EmployeeScan extends StatefulWidget {
  const EmployeeScan({super.key});

  @override
  State<EmployeeScan> createState() => _EmployeeScanState();
}

class _EmployeeScanState extends State<EmployeeScan> {
  bool _isProcessing = false;
  bool _isFlashOn = false;
  MobileScannerController cameraController = MobileScannerController();

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      cameraController.toggleTorch();
    });
  }

  void _handleScan(String bookingId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // ปิดกล้องชั่วคราวเพื่อป้องกันการสแกนซ้ำ
    cameraController.stop();

    try {
      final ticketRef =
          FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final ticketSnapshot = await ticketRef.get();

      if (ticketSnapshot.exists) {
        final ticketData = ticketSnapshot.data();
        String status = ticketData?['Status'] ?? 'unknown';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ScanCheck(bookingId: bookingId, status: status),
          ),
        ).then((_) {
          // เปิดกล้องอีกครั้งเมื่อกลับมาจากหน้าถัดไป
          cameraController.start();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket not found!")),
        );
        cameraController.start();
      }
    } catch (e) {
      print("Error scanning ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket is time out.")),
      );
      cameraController.start();
    }

    // เพิ่มดีเลย์ก่อนให้สแกนใหม่ได้
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Employee Scan",
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: Colors.white, 
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (barcodeCapture) {
              for (final barcode in barcodeCapture.barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  String? bookingId = _extractBookingId(barcode.rawValue!);
                  if (bookingId != null) {
                    _handleScan(bookingId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid QR code format")),
                    );
                  }
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
                  "Align QR bookingId here",
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

  String? _extractBookingId(String qrData) {
    try {
      final lines = qrData.split('\n');
      for (final line in lines) {
        if (line.startsWith('BookingID: ')) {
          return line.substring('BookingID: '.length);
        }
      }
      return null;
    } catch (e) {
      print("Error extracting bookingId: $e");
      return null;
    }
  }
}
