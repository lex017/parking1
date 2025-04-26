import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScanCheck extends StatefulWidget {
  final String bookingId;
  final String status;

  const ScanCheck({Key? key, required this.bookingId, required this.status})
      : super(key: key);

  @override
  State<ScanCheck> createState() => _ScanCheckState();
}

class _ScanCheckState extends State<ScanCheck> {
   String status = 'Loading...';
  String? collectionType;
  DateTime? checkOutTime;
  String? nameParking;
  String? plateNumber;

  @override
  void initState() {
    super.initState();
    _fetchTicketStatus();
  }

  Future<void> _fetchTicketStatus() async {
    try {
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId);
      final bookingSnap = await bookingRef.get();

      if (bookingSnap.exists) {
        var data = bookingSnap.data() as Map<String, dynamic>;
        setState(() {
          collectionType = 'bookings';
          status = data['Status'] ?? 'unknown';
          nameParking = data['nameParking'] ?? '-';
          plateNumber = data['plate'] ?? '-';
          if (data['checkOutTime'] != null) {
            checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
          }
        });
      } else {
        final ticketRealRef = FirebaseFirestore.instance
            .collection('ticketreal')
            .doc(widget.bookingId);
        final ticketRealSnap = await ticketRealRef.get();

        if (ticketRealSnap.exists) {
          var data = ticketRealSnap.data() as Map<String, dynamic>;
          setState(() {
            collectionType = 'ticketreal';
            status = data['Status'] ?? 'unknown';
            nameParking = data['nameParking'] ?? '-';
            plateNumber = data['plate'] ?? '-';
            if (data['checkOutTime'] != null) {
              checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
            }
          });
        } else {
          setState(() {
            status = 'not_found';
          });
        }
      }
    } catch (e) {
      print("Error fetching ticket status: $e");
      setState(() {
        status = 'error';
      });
    }
  }

  // Future<void> _fetchTicketStatus() async {
  //   try {
  //     final bookingRef = FirebaseFirestore.instance
  //         .collection('bookings')
  //         .doc(widget.bookingId);
  //     final bookingSnap = await bookingRef.get();

  //     if (bookingSnap.exists) {
  //       var data = bookingSnap.data() as Map<String, dynamic>;
  //       setState(() {
  //         collectionType = 'bookings';
  //         status = data['Status'] ?? 'unknown';
  //         if (data['checkOutTime'] != null) {
  //           checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
  //         }
  //       });
  //     } else {
  //       final ticketRealRef = FirebaseFirestore.instance
  //           .collection('ticketreal')
  //           .doc(widget.bookingId);
  //       final ticketRealSnap = await ticketRealRef.get();

  //       if (ticketRealSnap.exists) {
  //         var data = ticketRealSnap.data() as Map<String, dynamic>;
  //         setState(() {
  //           collectionType = 'ticketreal';
  //           status = data['Status'] ?? 'unknown';
  //           if (data['checkOutTime'] != null) {
  //             checkOutTime = (data['checkOutTime'] as Timestamp).toDate();
  //           }
  //         });
  //       } else {
  //         setState(() {
  //           status = 'not_found';
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print("Error fetching ticket status: $e");
  //     setState(() {
  //       status = 'error';
  //     });
  //   }
  // }

  Future<void> _handleCheckIn() async {
    if (collectionType == null) return;

    final ticketRef = FirebaseFirestore.instance
        .collection(collectionType!)
        .doc(widget.bookingId);

    try {
      await ticketRef.update({"Status": "check-in"});
      setState(() {
        status = "check-in";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-in successful!")),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print("Error updating check-in status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update check-in status.")),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    if (collectionType == null) return;

    final ticketRef = FirebaseFirestore.instance
        .collection(collectionType!)
        .doc(widget.bookingId);
    final now = DateTime.now();

    try {
      await ticketRef.update({
        "Status": "check-out",
        "checkOutTime": FieldValue.serverTimestamp(),
      });
      setState(() {
        status = "check-out";
        checkOutTime = now;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-out successful!")),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print("Error updating check-out status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update check-out status.")),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('hh:mm a, MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ticket Status"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF73AEF5), Color(0xFF61A4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan Check',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Status: ${status == 'loading' ? 'Fetching...' : status}",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ticket ID: ${widget.bookingId}',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Status: $status',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          if (checkOutTime != null)
                            Text(
                                'Check-out Time: ${_formatDateTime(checkOutTime!)}',
                                style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (status == "pending")
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleCheckIn,
                      icon: const Icon(Icons.login),
                      label: const Text(
                        "Check-in",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  if (status == "check-in")
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleCheckOut,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Check-out",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  if (status == "not_found")
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Ticket not found!",
                        style: TextStyle(color: Colors.red, fontSize: 20),
                      ),
                    ),
                  if (status == "check-out" && checkOutTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        "Checked out at: ${_formatDateTime(checkOutTime!)}",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
