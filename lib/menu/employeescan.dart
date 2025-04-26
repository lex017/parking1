import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parking1/menu/emp_check.dart';

class EmployeeScan extends StatefulWidget {
  final String empId;
  const EmployeeScan({super.key, required this.empId});

  @override
  State<EmployeeScan> createState() => _EmployeeScanState();
}

class _EmployeeScanState extends State<EmployeeScan> {
  bool _isProcessing = false;
  bool _isFlashOn = false;
  MobileScannerController cameraController = MobileScannerController();
  late String empId = widget.empId;

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      cameraController.toggleTorch();
    });
  }

  // Handle scan for both booking and ticket IDs
  void _handleScan(String barcodeData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    cameraController.stop();

    try {
      // Get employee details
      String employeeId = widget.empId;
      final employeeRef = FirebaseFirestore.instance.collection('employees').doc(employeeId);
      final employeeSnapshot = await employeeRef.get();

      if (!employeeSnapshot.exists) {
        throw Exception("Employee not found");
      }

      String employeeLocationId = employeeSnapshot.data()?['locationId'];

      // Extract bookingId or ticketId from QR code
      String? bookingId = _extractBookingId(barcodeData);
      String? ticketId = _extractTicketId(barcodeData);

      if (bookingId != null) {
        // Handle booking case
        await _processBooking(bookingId, employeeLocationId);
      } else if (ticketId != null) {
        // Handle ticket case
        await _processTicket(ticketId, employeeLocationId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR code format")),
        );
      }
    } catch (e) {
      print("Error scanning ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket is time out or not found.")),
      );
    } finally {
      cameraController.start();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processBooking(String bookingId, String employeeLocationId) async {
    // Check in the 'bookings' collection first
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
    final bookingSnapshot = await bookingRef.get();

    if (bookingSnapshot.exists) {
      final bookingData = bookingSnapshot.data();
      String bookingLocationId = bookingData?['locationId'];
      String status = bookingData?['Status'] ?? 'unknown';

      if (employeeLocationId == bookingLocationId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanCheck(
              bookingId: bookingId,
              status: status,
            ),
          ),
        ).then((_) {
          cameraController.start();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket not found in your location")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking not found")),
      );
    }
  }

  Future<void> _processTicket(String ticketId, String employeeLocationId) async {
    // If not found in 'bookings', check in 'ticketreal' collection
    final ticketRealRef = FirebaseFirestore.instance.collection('ticketreal').doc(ticketId);
    final ticketRealSnapshot = await ticketRealRef.get();

    if (ticketRealSnapshot.exists) {
      final ticketRealData = ticketRealSnapshot.data();
      String ticketRealLocationId = ticketRealData?['locationId'];
      String status = ticketRealData?['Status'] ?? 'unknown';

      if (employeeLocationId == ticketRealLocationId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanCheck(
              bookingId: ticketId, // Use ticketId instead of bookingId here
              status: status,
            ),
          ),
        ).then((_) {
          cameraController.start();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket not found in your location")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket not found")),
      );
    }
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
                  _handleScan(barcode.rawValue!);
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
        ],
      ),
    );
  }

  // Extract bookingId from QR code
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

  // Extract ticketId from QR code
  String? _extractTicketId(String qrData) {
    try {
      final lines = qrData.split('\n');
      for (final line in lines) {
        if (line.startsWith('TicketID: ')) {
          return line.substring('TicketID: '.length);
        }
      }
      return null;
    } catch (e) {
      print("Error extracting ticketId: $e");
      return null;
    }
  }
}
