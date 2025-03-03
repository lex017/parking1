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

  void _handleScan(String bookingId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check Firestore if the ticket exists
      final ticketRef =
          FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final ticketSnapshot = await ticketRef.get();

      if (ticketSnapshot.exists) {
        final ticketData = ticketSnapshot.data();
        String status = ticketData?['parkingStatus'] ?? 'unknown';

        // Navigate to confirmation page with actual status
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanCheck(bookingId: bookingId, status: status),
          ),
        );
      } else {
        // Show error message if ticket does not exist
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket not found!")),
        );
      }
    } catch (e) {
      print("Error scanning ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching ticket.")),
      );
    }

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
            onDetect: (barcodeCapture) {
              for (final barcode in barcodeCapture.barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  // Extract the bookingId from the QR data
                  String? bookingId = _extractBookingId(barcode.rawValue!);
                  if (bookingId != null) {
                    _handleScan(bookingId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid QR code format")),
                    );
                    setState(() {
                      _isProcessing = false;
                    });
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
    // Assuming the QR data is in the format: "BookingID: <bookingId>\n..."
    try {
      final lines = qrData.split('\n');
      for (final line in lines) {
        if (line.startsWith('BookingID: ')) {
          return line.substring('BookingID: '.length);
        }
      }
      return null; // BookingID not found
    } catch (e) {
      print("Error extracting bookingId: $e");
      return null;
    }
  }
}