import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanCheck extends StatefulWidget {
  final String bookingId;
  final String status;

  const ScanCheck({super.key, required this.bookingId, required this.status});

  @override
  State<ScanCheck> createState() => _ScanCheckState();
}

class _ScanCheckState extends State<ScanCheck> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.status; // ใช้สถานะที่รับมาจากหน้าก่อน
    _fetchTicketStatus();
  }

  // ดึงสถานะของตั๋วจาก Firestore
  Future<void> _fetchTicketStatus() async {
    try {
      final ticketRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
      final ticketSnapshot = await ticketRef.get();

      if (ticketSnapshot.exists) {
        setState(() {
          status = ticketSnapshot.data()?['parkingStatus'] ?? 'unknown';
        });
      } else {
        setState(() {
          status = "not_found";
        });
      }
    } catch (e) {
      print("Error fetching ticket status: $e");
      setState(() {
        status = "error";
      });
    }
  }

  // อัปเดตสถานะเป็น Check-in
  Future<void> _handleCheckIn() async {
    final ticketRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);

    try {
      await ticketRef.update({"parkingStatus": "check-in"});
      setState(() {
        status = "check-in";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-in successful!")),
      );
    } catch (e) {
      print("Error updating check-in status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update check-in status.")),
      );
    }
  }

  // อัปเดตสถานะเป็น Check-out (ไม่ลบข้อมูล)
  Future<void> _handleCheckOut() async {
    final ticketRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);

    try {
      await ticketRef.update({"parkingStatus": "check-out"});
      setState(() {
        status = "check-out";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-out successful!")),
      );

      // กลับไปหน้าก่อนหลังจากแสดงผล 1 วินาที
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      print("Error updating check-out status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update check-out status.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan Check',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Status: ${status == 'loading' ? 'Fetching...' : status}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  if (status == "pending") 
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _handleCheckIn,
                      icon: const Icon(Icons.login),
                      label: const Text(
                        "Check-in",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                  if (status == "check-in")
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _handleCheckOut,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Check-out",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                  if (status == "not_found")
                    const Text(
                      "Ticket not found!",
                      style: TextStyle(color: Colors.red, fontSize: 18),
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
